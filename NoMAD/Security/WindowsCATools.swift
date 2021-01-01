//
//  WindowsCATools.swift
//  NoMAD
//
//  Created by Joel Rennich on 5/15/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

import Foundation
import Security
import CommonCrypto
//import TCSCertificateRequest

class WindowsCATools {

    // set up lots of constants

    private var api: String
    var certCSR: String
    var certTemplate: String
    var caServer: String
    var myImportError: OSStatus

    private let kCryptoExportImportManagerPublicKeyInitialTag = "-----BEGIN RSA PUBLIC KEY-----\n"
    private let kCryptoExportImportManagerPublicKeyFinalTag = "-----END RSA PUBLIC KEY-----\n"

    private let kCryptoExportImportManagerRequestInitialTag = "-----BEGIN CERTIFICATE REQUEST-----\n"
    private let kCryptoExportImportManagerRequestFinalTag = "-----END CERTIFICATE REQUEST-----\n"

    private let kCryptoExportImportManagerPublicNumberOfCharactersInALine = 64

    var err = OSStatus()

    var pubKey : SecKey? = nil
    var privKey : SecKey? = nil
    var pubKeyBits : CFTypeRef? = nil
    var privKeyBits : CFTypeRef? = nil

    var pubKeyData : Data? = nil
    var pubKeyDataPtr : CFData? = nil
    
    var uuid : CFUUID? = nil
    var uuidString : String? = nil

    var now : String? = nil

    var kPrivateKeyTag : String? = nil
    var kPublicKeyTag : String? = nil

    var sema : DispatchObject? = nil
    var prefs = PrefManager()

    init(serverURL: String, template: String) {

        // TODO: Validate the URL

        self.api = "\(serverURL)/certsrv/"
        caServer = serverURL
        uuid = CFUUIDCreate(nil)
        uuidString = CFUUIDCreateString(nil, uuid) as String?

        // we should return this in case there's an error


        certCSR = ""

        certTemplate = template
        myImportError = 0

        now = String(describing: NSDate())

        kPrivateKeyTag = "com.NoMAD.CSR.privatekey." + now!
        kPublicKeyTag = "com.NoMAD.CSR.publickey." + now!

        sema = DispatchSemaphore( value: 0 )
    }
    
    func TCSCertEnroll() {
        // generate the keypair
        
        print("Generating keys for RPC cert request")
        
        genKeys()
        let myPubKeyData = getPublicKeyasData()
        let myCSRGen = CertificateSigningRequest(commonName: "NoMAD", organizationName: "Orchard & Grove", organizationUnitName: "WorldHQ", countryName: "US", cryptoAlgorithm: CryptoAlgorithm.sha1)
        
        let myCSR = myCSRGen.build(myPubKeyData, privateKey: privKey!)
        
        print("RPC CA settings:")
        
        print(prefs.string(for: PrefKeys.x509Name) as Any)
        print(prefs.string(for: PrefKeys.x509CA) as Any)
        print(prefs.string(for: PrefKeys.template) as Any)
        
        var certReq : AnyObject? = nil
        
        do {
        certReq = try TCSADCertificateRequest.init(serverName: prefs.string(for: PrefKeys.x509CA), certificateAuthorityName: prefs.string(for: PrefKeys.x509Name), certificateTemplate: prefs.string(for: PrefKeys.template), verbose: true)
        } catch {
            print("Unable to init RPC cert request")
            return
        }
        
        do {
            print("Submitting CSR to CA")
            
            let signedCSR = try certReq?.submitRequestToActiveDirectory(withCSR: myCSR)
            let myCertRef = SecCertificateCreateWithData(nil, signedCSR! as CFData)
            
            if myCertRef == nil {
                myLogger.logit(.base, message: "Error getting certificate. Check template name and other configuration settings.")
                return
            }
            
            let dictionary: [NSString: AnyObject] = [
                kSecClass: kSecClassCertificate,
                kSecReturnRef : kCFBooleanTrue,
                kSecValueRef: myCertRef!
            ];
            
            var mySecRef : AnyObject? = nil
            
            print("Adding signed public cert to Keychain")
            
            self.myImportError = SecItemAdd(dictionary as CFDictionary, &mySecRef)
            
            var myIdentityRef : SecIdentity? = nil
            
            print("Creating identity in keychain")
            
            SecIdentityCreateWithCertificate(nil, myCertRef!, &myIdentityRef)
            
            if let networks = prefs.array(for: PrefKeys.wifiNetworks) {
                for network in networks as! [String] {
                    SecIdentitySetPreferred(myIdentityRef, ("com.apple.network.eap.user.identity.wlan.ssid." + network) as CFString , nil)
                }
            }
        } catch {
            print("RPC cert request failed")
            return
        }
        print("Completed RPC Cert request")
    }

    func certEnrollment() -> OSStatus {

        // generate the keypair 

        genKeys()
        let myPubKeyData = getPublicKeyasData()
        let myCSRGen = CertificateSigningRequest(commonName: "NoMAD", organizationName: "Orchard & Grove", organizationUnitName: "WorldHQ", countryName: "US", cryptoAlgorithm: CryptoAlgorithm.sha1)
        print(myPubKeyData)

        let myCSR = myCSRGen.build(myPubKeyData, privateKey: privKey!)

        certCSR = PEMKeyFromDERKey(myCSR!, PEMType: "CSR")

        var myReqID = 0

        submitCert(certTemplate: certTemplate, completionHandler: { (data, response, error) in
            if (response != nil) {

                let httpResponse = response as! HTTPURLResponse

                if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 500) {
                }            }

            if (data != nil ) {
                do {
                    myReqID = try self.findReqID(data: data!)
                } catch {
                }
                self.getCert( certID: myReqID, completionHandler: { (data, response, error) in
                    if (response != nil) {
                        let httpResponse = response as! HTTPURLResponse

                        if (httpResponse.statusCode >= 200 && httpResponse.statusCode < 500) {
                        }            }

                    if (data != nil ) {

                        let myCertRef = SecCertificateCreateWithData(nil, data! as CFData)

                        if myCertRef == nil {
                            myLogger.logit(.base, message: "Error getting certificate. Check template name and other configuration settings.")
                            return
                        }

                        let dictionary: [NSString: AnyObject] = [
                            kSecClass: kSecClassCertificate,
                            kSecReturnRef : kCFBooleanTrue,
                            kSecValueRef: myCertRef!
                        ];

                        var mySecRef : AnyObject? = nil

                        self.myImportError = SecItemAdd(dictionary as CFDictionary, &mySecRef)

                        var myIdentityRef : SecIdentity? = nil

                        SecIdentityCreateWithCertificate(nil, myCertRef!, &myIdentityRef)
                        
                        if let networks = self.prefs.array(for: PrefKeys.wifiNetworks) {
                            for network in networks as! [String] {
                                SecIdentitySetPreferred(myIdentityRef, ("com.apple.network.eap.user.identity.wlan.ssid." + network) as CFString , nil)
                            }
                        }
                    }

                    if (error != nil) {
                        print(error as Any)
                    }
                })

            }

            if (error != nil) {
                print(error as Any)
            }
        })
        return self.myImportError
    }

    func submitCert(certTemplate: String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {

        let request = NSMutableURLRequest(url: (NSURL(string: "\(api)certfnsh.asp"))! as URL)
        request.httpMethod = "POST"

        let unreserved = "*-._/"
        let allowed = NSMutableCharacterSet.alphanumeric()
        allowed.addCharacters(in: unreserved)

        let encodedCertRequestFinal = certCSR.addingPercentEncoding(withAllowedCharacters: allowed as CharacterSet)

        let body = "CertRequest=" + encodedCertRequestFinal! + "&SaveCert=yes&Mode=newreq&CertAttrib=CertificateTemplate:" + certTemplate
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        request.httpBody = body.data(using: String.Encoding.utf8)

        let session = URLSession.shared
        session.dataTask(with: request as URLRequest, completionHandler: completionHandler).resume()
    }

    func findReqID(data: Data) throws -> Int {

        let response = String(data: data, encoding: String.Encoding.utf8)
        var myresponse = "0"

        if response!.contains("certnew.cer?ReqID=") {
            let responseLines = response?.components(separatedBy: "\n")
            let reqIDRegEx = try NSRegularExpression(pattern: ".*ReqID=", options: NSRegularExpression.Options.caseInsensitive)
            let reqIDRegExEnd = try NSRegularExpression(pattern: "&amp.*", options: NSRegularExpression.Options.caseInsensitive)

            for line in responseLines! {
                if line.contains("certnew.cer?ReqID=") {
                    myresponse = reqIDRegEx.stringByReplacingMatches(in: line, options: [], range: NSMakeRange(0, line.count), withTemplate: "")
                    myresponse = reqIDRegExEnd.stringByReplacingMatches(in: myresponse, options: [], range: NSMakeRange(0, myresponse.count), withTemplate: "").replacingOccurrences(of: "\r", with: "")
                    return Int(myresponse) ?? 0
                }
            }
        } else {
            return 0
        }
        return Int(myresponse) ?? 0
    }
    
    func getCert(certID: Int, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        
        let request = NSMutableURLRequest(url: (NSURL(string: "\(api)certnew.cer?ReqID=" + String(certID) + "&Enc=bin"))! as URL)
        
        request.httpMethod = "GET"
        
        let session = URLSession.shared
        session.dataTask(with: request as URLRequest, completionHandler: completionHandler).resume()
    }

    // utility functions

    func genKeys() {

        let privKeyGenDict: [String:AnyObject] = [
            kSecAttrApplicationTag as String : kPrivateKeyTag!.data(using: String.Encoding.utf8)! as AnyObject,
            ]

        let pubKeyGenDict: [String:AnyObject] = [
            kSecAttrApplicationTag as String : kPublicKeyTag!.data(using: String.Encoding.utf8)! as AnyObject,
            ]

        // first generate the keypair
        
        let privateKeyName = "NoMAD:" + (prefs.string(for: PrefKeys.userEmail) ?? (prefs.string(for: PrefKeys.userShortName))!)

        var keyGenDict: [String:AnyObject] = [

            // this sets if you can extract the private key
            kSecAttrIsExtractable as String : false as AnyObject,

            kSecAttrKeyType as String : kSecAttrKeyTypeRSA as AnyObject,
            kSecAttrKeySizeInBits as String : "2048" as CFString,
            kSecAttrIsPermanent as String : true as AnyObject,
            kSecAttrLabel as String : privateKeyName as AnyObject,
            kSecPrivateKeyAttrs as String : privKeyGenDict as CFDictionary,
            kSecPublicKeyAttrs as String : pubKeyGenDict as CFDictionary,
            ]
        
        if prefs.bool(for: PrefKeys.allowEAPOL) {
            
            var access : SecAccess? = nil
            
            var eapolSecTrust : SecTrustedApplication? = nil
            var airportdSecTrust : SecTrustedApplication? = nil
            var nomadSecTrust : SecTrustedApplication? = nil
            
            err = SecTrustedApplicationCreateFromPath("/System/Library/SystemConfiguration/EAPOLController.bundle/Contents/Resources/eapolclient", &eapolSecTrust)
            err = SecTrustedApplicationCreateFromPath("/usr/libexec/airportd", &airportdSecTrust)
            err = SecTrustedApplicationCreateFromPath(CommandLine.arguments[0], &nomadSecTrust)
            err = SecAccessCreate("NoMAD Cert" as CFString, [ eapolSecTrust, airportdSecTrust, nomadSecTrust] as CFArray, &access)
            
            if err == 0 {
                keyGenDict[kSecAttrAccess as String] = access as AnyObject
            }
        }

        if prefs.bool(for: PrefKeys.exportableKey) {
            keyGenDict["extr"] = true as AnyObject
        }

        err = SecKeyGeneratePair(keyGenDict as CFDictionary, &pubKey, &privKey)
        
        print(SecCopyErrorMessageString(err, nil)!)

    }

    func getPublicKeyasData() -> Data {

        // get the public key

        let pubKeyDict: [String:AnyObject] = [
            kSecClass as String : kSecClassKey as AnyObject,
            kSecReturnData as String : true as AnyObject,
            kSecAttrKeyType as String : kSecAttrKeyTypeRSA as AnyObject,
            kSecAttrApplicationTag as String : kPublicKeyTag!.data(using: String.Encoding.utf8)! as AnyObject,
            ]

        err = SecItemExport(pubKey!, SecExternalFormat.formatBSAFE, .init(rawValue: 0), nil, &pubKeyDataPtr)
        
        err = SecItemCopyMatching(pubKeyDict as CFDictionary, &pubKeyBits)
        
        pubKeyData = (pubKeyDataPtr! as Data)
        
        return pubKeyDataPtr! as Data
        
    }

    func PEMKeyFromDERKey(_ data: Data, PEMType: String) -> String {

        var resultString: String

        // base64 encode the result
        let base64EncodedString = data.base64EncodedString(options: [])

        // split in lines of 64 characters.
        var currentLine = ""
        if PEMType == "RSA" {
            resultString = kCryptoExportImportManagerPublicKeyInitialTag
        } else {
            resultString = kCryptoExportImportManagerRequestInitialTag
        }
        var charCount = 0
        for character in base64EncodedString {
            charCount += 1
            currentLine.append(character)
            if charCount == kCryptoExportImportManagerPublicNumberOfCharactersInALine {
                resultString += currentLine + "\n"
                charCount = 0
                currentLine = ""
            }
        }
        // final line (if any)
        if currentLine.count > 0 { resultString += currentLine + "\n" }
        // final tag
        if PEMType == "RSA" {
            resultString += kCryptoExportImportManagerPublicKeyFinalTag
        } else {
            resultString += kCryptoExportImportManagerRequestFinalTag
        }
        return resultString
    }

    func build8021x() {
        
    }
}
