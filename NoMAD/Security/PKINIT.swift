//
//  PKINIT.swift
//  NoMAD
//
//  Created by Joel Rennich on 12/28/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import LocalAuthentication
import CryptoTokenKit
import GSS

protocol PKINITCallbacks {
    func cardChange()
}

struct PKINITCert {
    let cn: String
    let principal: String?
    let pubKeyHash: String
    let identity: SecIdentity
    let cert: SecCertificate
}

class PKINIT: NSObject {
    
    static var shared = PKINIT()
    var delegates = [PKINITCallbacks]()
    
    var cardInserted: Bool {
        get {
            for token in tkWatcher.tokenIDs {
                if token.containsIgnoringCase("pivtoken") {
                    return true
                }
            }
            return false
        }
    }
    
    var running = false
    
    let tkWatcher = TKTokenWatcher()

    func startWatching() {
        tkWatcher.setInsertionHandler({ token in
            myLogger.logit(.debug, message: "Token inserted: \(token)")
            self.updateDelegates()
            self.tkWatcher.addRemovalHandler({ token in
                print("Token removed: \(token)")
                self.updateDelegates()
            }, forTokenID: token)
        })
    }
    
    func returnCerts() -> [PKINITCert]? {
        
        var certs =  [PKINITCert]()
        let query: [String: Any] = [
            
            // this will only find items provided by a CTK Token
            // remove the kSecAttrAccessGroup to find all certs
            kSecAttrAccessGroup as String: kSecAttrAccessGroupToken,
            
            kSecAttrKeyClass as String : kSecAttrKeyClassPrivate,
            kSecClass as String : kSecClassIdentity,
            kSecReturnAttributes as String : kCFBooleanTrue as Any,
            kSecReturnRef as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnPersistentRef as String: kCFBooleanTrue as Any
        ]
        
        var result: AnyObject?
        
        let err = SecItemCopyMatching(query as CFDictionary, &result)
        
        if err == 0 {
            if let items = result as? [[String:Any]] {
                for item in items {
                    if let itemLabel = item["labl"] as? String,
                       let certPubKeyHash = item["pkhh"] as? Data {
                        print("Found: \(itemLabel)")
                        let secRef = item["v_Ref"] as! SecIdentity
                        var cert: SecCertificate?
                        let _ = SecIdentityCopyCertificate(secRef, &cert)
                        let certPubKeyHashString = certPubKeyHash.hexEncodedString().uppercased()
                        if let certUnwrapped = cert {
                            let newCert = PKINITCert(cn: itemLabel, principal: getPrincipal(cert: certUnwrapped), pubKeyHash: certPubKeyHashString, identity: secRef, cert: certUnwrapped)
                            certs.append(newCert)
                        }
                    }
                }
            }
        }
        
        if certs.count > 0 {
            return certs
        } else {
            return nil
        }
    }
    
    func authWithCert(identity: SecIdentity, user: String, pin: String) -> String {
        running = true
        
        let context = LAContext.init()
        
        context.setCredential(pin.data(using: String.Encoding.utf8), type: LACredentialType(rawValue: -3)!)
        
        if #available(OSX 10.13, *) {
            context.interactionNotAllowed = true
        } else {
            // Fallback on earlier versions
        }
        
        var cred: gss_cred_id_t? = gss_cred_id_t.init(bitPattern: 1)
        
        var err: Unmanaged<CFError>? = nil
        let name = GSSCreateName(user as CFTypeRef, &__gss_c_nt_user_name_oid_desc, &err)
        
        let attrs: [String:AnyObject] = [
            kGSSICCertificate as String: identity as AnyObject,
            kGSSICAuthenticationContext as String: context as AnyObject,
        ]
        
        let major = gss_aapl_initial_cred(name!, &__gss_krb5_mechanism_oid_desc, attrs as CFDictionary, &cred!, &err)
        
        running = false
        
        if major == 0 {
            return ""
        } else {
            return err.debugDescription
        }
    }
    
    private func getPrincipal(cert: SecCertificate) -> String? {
        
        // get all the OIDS
        
        guard let myOIDs : NSDictionary = SecCertificateCopyValues(cert, nil, nil) else { return nil }
                
        // find which OID we want
        
            if myOIDs["2.5.29.17"] == nil {
                return nil
            }
            
            guard let myUPNRaw = myOIDs["2.5.29.17"] as? NSDictionary else { return nil }
            guard let myUPNValues = myUPNRaw["value"] as? NSArray else { return nil }
            for item in myUPNValues {
                // cast to dictionary
                guard let itemDict = item as? NSDictionary else { return nil }
                guard let itemValue = itemDict["value"] as? String else { return nil }
                if itemValue.contains("@") {
                    return itemValue
                }
            }
        return nil
    }
    
    private func updateDelegates() {
        for delegate in delegates {
            delegate.cardChange()
        }
    }
}
