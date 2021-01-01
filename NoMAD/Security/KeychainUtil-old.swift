//
//  KeychainUtil.swift
//  NoMAD
//
//  Created by Joel Rennich on 8/7/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

// class to manage all keychain interaction

import Foundation
import Security

struct certDates {
    var serial: String
    var expireDate: Date
    var expireInt: Int
    var certRef: SecIdentity?
}

struct KeychaItem {
    var account : String
    var itemClass : String
    var label : String
    var service : String
    var appPath : [String]?
    var teamID : [String]?
}

class KeychainUtil {
    
    var myErr: OSStatus
    let serviceName = "NoMAD"
    var passLength: UInt32 = 0
    var passPtr: UnsafeMutableRawPointer?
    var myKeychainItem: SecKeychainItem?
    var prefs = PrefManager()
    
    let sharedKeychainName = "VRPY9KHGX6.menu.nomad.nomad" //kSecAttrAccessGroup
    
    init() {
        myErr = 0
    }
    
    // find if there is an existing account password and return it or throw
    
    func findPassword(_ name: String) throws -> String {
        
        // clean up anything lingering
        
        passPtr = nil
        passLength = 0
        
        var searchReturn: AnyObject? = nil

        let attributes = [kSecClass: kSecClassGenericPassword,
                          kSecAttrService: serviceName,
                          kSecAttrAccessGroup : sharedKeychainName,
                          kSecAttrAccount: name,
                          kSecAttrAccessGroup: accessGroup,
                          kSecReturnData: true,
                          kSecAttrSynchronizable as String : kCFBooleanTrue!,
                          kSecReturnAttributes: true] as [String: Any]
        myErr = SecItemCopyMatching(attrs as CFDictionary, &searchReturn)

        if myErr == OSStatus(errSecSuccess) {
            let password = NSString(bytes: passPtr!, length: Int(passLength), encoding: String.Encoding.utf8.rawValue)
            return password! as String
        } else {
            // now check for all lowercase password just in case
            
            if name == name.lowercased() {
                // already lowercase, no need to check again
                
                throw NoADError.noStoredPassword
            }
            
            myErr = SecKeychainFindGenericPassword(nil, UInt32(serviceName.count), serviceName, UInt32(name.lowercased().count), name.lowercased(), &passLength, &passPtr, &myKeychainItem)
            
            if myErr == OSStatus(errSecSuccess) {
                let password = NSString(bytes: passPtr!, length: Int(passLength), encoding: String.Encoding.utf8.rawValue)
                return password! as String
            } else {
                
                // now to look for /anything/ that might match
                
                var searchReturn: AnyObject? = nil
                
                let attrs = [
                    kSecClass : kSecClassGenericPassword,
                    kSecAttrService : serviceName,
                    kSecAttrAccessGroup : sharedKeychainName,
                    kSecReturnRef : true,
                    kSecReturnAttributes : true,
                    kSecMatchLimit : kSecMatchLimitAll,
                    ] as [CFString : Any]
                
                myErr = SecItemCopyMatching(attrs as CFDictionary, &searchReturn)
                
                if myErr != 0 || searchReturn == nil {
                    // no results throw
                    throw NoADError.noStoredPassword
                }
                
                let returnDict = searchReturn as! CFArray as Array
                for item in returnDict {
                    if ((item["acct"] as? String ?? "").lowercased() == name.lowercased()) {
                        // got a match now let's lookup the password
                        
                        myErr = SecKeychainFindGenericPassword(nil, UInt32(serviceName.count), serviceName, UInt32((item["acct"] as? String ?? "").count), (item["acct"] as? String ?? ""), &passLength, &passPtr, &myKeychainItem)
                        
                        if myErr == OSStatus(errSecSuccess) {
                            let password = NSString(bytes: passPtr!, length: Int(passLength), encoding: String.Encoding.utf8.rawValue)
                            return password! as String
                        } else {
                            throw NoADError.noStoredPassword
                        }
                    }
                }
                throw NoADError.noStoredPassword
            }
        }
    }
    
    // set the password
    
    func setPassword(_ name: String, pass: String) -> OSStatus {
        
        let attributes = [kSecClass: kSecClassGenericPassword,
                          kSecAttrService: serviceName,
                          kSecAttrAccessGroup : sharedKeychainName,
                          kSecAttrAccount: name,
                          kSecAttrSynchronizable as String : kCFBooleanTrue!,
                          kSecValueData: pass] as [String: Any]
        return SecItemAdd(attributes as CFDictionary, nil)
        
        //myErr = SecKeychainAddGenericPassword(nil, UInt32(serviceName.count), serviceName, UInt32(name.count), name, UInt32(pass.count), pass, nil)
        
        return myErr
    }
    
    // update the password
    
    func updatePassword(_ name: String, pass: String) -> Bool {
        if (try? findPassword(name)) != nil {
            let _ = deletePassword()
        }
        myErr = setPassword(name, pass: pass)
        if myErr == OSStatus(errSecSuccess) {
            return true
        } else {
            myLogger.logit(LogLevel.base, message: "Unable to update keychain password.")
            return false
        }
    }
    
    // delete the password from the keychain
    
    func deletePassword() -> OSStatus {
        myErr = SecKeychainItemDelete(myKeychainItem!)
        return myErr
    }
    
    // check to see if the deafult Keychain is locked
    
    func checkLockedKeychain() -> Bool {
        
        var myKeychain: SecKeychain?
        var myKeychainStatus = SecKeychainStatus()
        
        // get the default keychain
        
        myErr = SecKeychainCopyDefault(&myKeychain)
        
        if myErr == OSStatus(errSecSuccess) {
            
            myErr = SecKeychainGetStatus(myKeychain, &myKeychainStatus)
            
            if Int(myKeychainStatus) == 2 {
                myLogger.logit(.debug, message: "Keychain is locked")
                return true
            }
            myLogger.logit(.debug, message: "Keychain is unlocked")
            return false
        } else {
            myLogger.logit(.debug, message: "Error checking to see if the Keychain is locked, assuming it is.")
            return true
        }
    }
    
    // convience functions
    
    func findAndDelete(_ name: String) -> Bool {
        do {
            let _ = try findPassword(name)
        } catch {
            return false
        }
        
        if  deletePassword() == 0 {
            return true
        } else {
            return false
        }
    }
    
    // return the last expiration date for any certs that match the domain and user
    
    func findCertExpiration(_ identifier: String, defaultNamingContext: String) -> Date? {
        
        var lastExpire = Date.distantPast
        
        let certList = findAllUserCerts(identifier, defaultNamingContext: defaultNamingContext)
        
        if certList == nil || certList!.count < 1 {
            return nil
        }
        
        for cert in certList! {
            if lastExpire.timeIntervalSinceNow < cert.expireDate.timeIntervalSinceNow {
                lastExpire = cert.expireDate
            }
        }
        return lastExpire
    }
    
    func findAllUserCerts(_ identifier: String, defaultNamingContext: String) -> [certDates]?{
        var matchingCerts = [certDates]()
        var myCert: SecCertificate? = nil
        var searchReturn: AnyObject? = nil
        
        // create a search dictionary to find Identitys with Private Keys and returning all matches
        
        /*
         @constant kSecMatchIssuers Specifies a dictionary key whose value is a
         CFArray of X.500 names (of type CFDataRef). If provided, returned
         certificates or identities will be limited to those whose
         certificate chain contains one of the issuers provided in this list.
         */
        
        // build our search dictionary
        
        let identitySearchDict: [String:AnyObject] = [
            kSecClass as String: kSecClassIdentity,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate as AnyObject,
            
            // this matches e-mail address
            //kSecMatchEmailAddressIfPresent as String : identifier as CFString,
            
            // this matches Common Name
            //kSecMatchSubjectContains as String : identifier as CFString,
            
            kSecReturnRef as String: true as AnyObject,
            kSecMatchLimit as String : kSecMatchLimitAll as AnyObject
        ]
        
        myErr = 0
        
        
        // look for all matches
        
        myErr = SecItemCopyMatching(identitySearchDict as CFDictionary, &searchReturn)
        
        if myErr != 0 {
            myLogger.logit(.base, message: "Error getting Certificates.")
            return nil
        }
        
        let foundCerts = searchReturn as! CFArray as Array
        
        if foundCerts.count == 0 {
            myLogger.logit(.info, message: "No certificates found.")
            return nil
        }
        
        for cert in foundCerts {
            
            myErr = SecIdentityCopyCertificate(cert as! SecIdentity, &myCert)
            
            if myErr != 0 {
                myLogger.logit(.base, message: "Error getting Certificate references.")
                return nil
            }
            
            // get the full OID set for the cert
            
            let myOIDs : NSDictionary = SecCertificateCopyValues(myCert!, nil, nil)!
            
            // look at the NT Principal name
            
            if myOIDs["2.5.29.17"] != nil {
                let SAN = myOIDs["2.5.29.17"] as! NSDictionary
                let SANValues = SAN["value"]! as! NSArray
                for values in SANValues {
                    let value = values as! NSDictionary
                    if String(_cocoaString: value["label"]! as AnyObject) == "1.3.6.1.4.1.311.20.2.3" {
                        if let myNTPrincipal = value["value"] {
                            // we have an NT Principal, let's see if it's Kerberos Principal we're looking for
                            myLogger.logit(.debug, message: "Certificate NT Principal: " + String(describing: myNTPrincipal) )
                            if String(describing: myNTPrincipal) == identifier {
                                myLogger.logit(.debug, message: "Found cert match")
                                
                                
                                // we have a match now gather the expire date and the serial
                                
                                var expireDate = Date.init(timeIntervalSince1970: 0)
                                
                                if let expireOID : NSDictionary = myOIDs["2.5.29.24"] as? NSDictionary {
                                    expireDate = expireOID["value"] as? Date ?? Date.init(timeIntervalSince1970: 0)
                                }
                                
                                // this finds the serial
                                
                                var serial = "000000"
                                
                                if let serialDict : NSDictionary = myOIDs["2.16.840.1.113741.2.1.1.1.3"] as? NSDictionary {
                                    serial = serialDict["value"] as? String ?? "000000"
                                }
                                
                                // pack the data up into a certDate
                                
                                let certificate = certDates( serial: serial, expireDate: expireDate, expireInt: Int(expireDate.timeIntervalSince1970), certRef: (cert as! SecIdentity))
                                
                                // append to the list
                                
                                matchingCerts.append(certificate)
                                
                            } else {
                                myLogger.logit(.debug, message: "Certificate doesn't match current user principal.")
                            }
                        }
                        
                    }
                }
            }
        }
        myLogger.logit(.debug, message: "Found " + String(matchingCerts.count) + " certificates.")
        myLogger.logit(.debug, message: "Found certificates: " + String(describing: matchingCerts) )
        
        return matchingCerts
    }
    
    func manageKeychainPasswords(newPassword: String) {
        
        var searchReturn: AnyObject? = nil
        
        // get the items to update
        
        myLogger.logit(.debug, message: "Attempting to update keychain items.")
        
        let myKeychainItems = prefs.dictionary(for: PrefKeys.keychainItems)
        
        // bail if there's nothing to update 
        
        if myKeychainItems?.count == 0 || myKeychainItems == nil {
            myLogger.logit(.debug, message: "No keychain items to update.")
            return
        }
        
        // set up the base search dictionary
        
        var itemSearch: [String:AnyObject] = [
            kSecClass as String: kSecClassGenericPassword as AnyObject,
            kSecMatchLimit as String : kSecMatchLimitAll as AnyObject,
            kSecReturnAttributes as String: true as AnyObject,
            kSecReturnRef as String : true as AnyObject,
            ]
        
        // set up the new password dictionary
        
        let attrToUpdate: [String:AnyObject] = [
            kSecValueData as String: newPassword.data(using: .utf8) as AnyObject
        ]
        
        for item in myKeychainItems! {
            
            if prefs.bool(for: PrefKeys.keychainItemsDebug) {
                print(item)
            }
            
            // add in the Service name
            
            itemSearch[kSecAttrService as String] = item.key as AnyObject
            
            var itemAccess: SecAccess? = nil
            var secApp: SecTrustedApplication? = nil
            var myACLs : CFArray? = nil
            
            
            // add in the swapped account name
            
            let account = (item.value as! String).variableSwap()
            
            if account != "" && account != "<<NONE>>" && account != "<<ANY>>" {
                itemSearch[kSecAttrAccount as String] = (item.value as! String).variableSwap() as AnyObject
            } else {
                // remove the account attribute if it's in there
                itemSearch.removeValue(forKey: kSecAttrAccount as String)
            }
            
            if prefs.bool(for: PrefKeys.keychainItemsDebug) {
                print(itemSearch)
            }
            
            myErr = SecItemCopyMatching(itemSearch as CFDictionary, &searchReturn)
            
            if searchReturn == nil {
                
                // no items found 
                continue
            }
            
            let items = searchReturn as! CFArray as Array
            
            // if no item, don't attempt to change
            
            if items.count < 1 {
                myLogger.logit(.debug, message: "Keychain item does not currently exist.")
                continue
            }
            
            for entry in items {
                
                // now to loop through and find out if the item is available
                // suppress the user UI first
                
                SecKeychainSetUserInteractionAllowed(false)
                
                let account = entry["acct"] as? String ?? ""
                let itemName = entry["labl"] as? String ?? ""
                let myKeychainItem = entry["v_Ref"] as! SecKeychainItem
                
                myErr = SecKeychainFindGenericPassword(nil, UInt32(itemName.count), itemName, UInt32(account.count), account, &passLength, &passPtr, nil)
                
                SecKeychainSetUserInteractionAllowed(true)
                
                passLength = 0
                passPtr = nil
                
                if myErr != 0 {
                    
                    myLogger.logit(.debug, message: "Adjusting ACL of keychain item \(itemName) : \(account)")
                    
                    myErr = SecKeychainItemCopyAccess(myKeychainItem, &itemAccess)
                    
                    myErr = SecTrustedApplicationCreateFromPath( nil, &secApp)
                    
                    // Decode ACL
                    
                    SecAccessCopyACLList(itemAccess!, &myACLs)
                    
                    var appList: CFArray? = nil
                    var desc: CFString? = nil
                    //                var newacl: AnyObject? = nil
                    var prompt = SecKeychainPromptSelector()
                    
                    for acl in myACLs as! Array<SecACL> {
                        SecACLCopyContents(acl, &appList, &desc, &prompt)
                        let authArray = SecACLCopyAuthorizations(acl)
                        
                        if !(authArray as! [String]).contains("ACLAuthorizationPartitionID") {
                            continue
                        }
                        
                        // pull in the description that's really a functional plist <sigh>
                        
                        let rawData = Data.init(fromHexEncodedString: desc! as String)
                        var format: PropertyListSerialization.PropertyListFormat = .xml
                        
                        var propertyListObject = try? PropertyListSerialization.propertyList(from: rawData!, options: [], format: &format) as! [ String: [String]]
                        
                        // add in the team ID that NoMAD is signed with if it doesn't already exist
                        
                        if !(propertyListObject!["Partitions"]?.contains("teamid:AAPZK3CB24"))! {
                            propertyListObject!["Partitions"]?.append("teamid:AAPZK3CB24")
                        }
                        
                        if prefs.bool(for: PrefKeys.keychainItemsDebug) {
                            myLogger.logit(.debug, message: String(describing: propertyListObject))
                        }
                        
                        // now serialize it back into a plist
                        
                        let xmlObject = try? PropertyListSerialization.data(fromPropertyList: propertyListObject as Any, format: format, options: 0)
                        
                        // Hi Rick, how's things?
                        
                        myErr = SecKeychainItemSetAccessWithPassword(myKeychainItem, itemAccess!, UInt32(newPassword.count), newPassword)
                        
                        // now that all ACLs has been adjusted, we can update the item
                        
                        myErr = SecItemUpdate(itemSearch as CFDictionary, attrToUpdate as CFDictionary)
                        
                        // now add NoMAD and the original apps back into the property object
                        
                        myErr = SecACLSetContents(acl, appList, xmlObject!.hexEncodedString() as CFString, prompt)
                        
                        // smack it again to set the ACL
                        
                        myErr = SecKeychainItemSetAccessWithPassword(myKeychainItem, itemAccess!, UInt32(newPassword.count), newPassword)
                    }
                    
                    // Hi Rick, how's things?
                    
                    myErr = SecKeychainItemSetAccessWithPassword(myKeychainItem, itemAccess!, UInt32(newPassword.count), newPassword)
                    
                    if myErr != 0 {
                        myLogger.logit(.base, message: "Error setting keychain ACL.")
                    }
                    
                } else {
                    myLogger.logit(.debug, message: "Keychain item \(itemName) : \(account) is available via ACLs.")
                }
            }
            
            if myErr == 0 {
                myLogger.logit(.debug, message: "Updated password for service: \(item.key)")
            } else {
                myLogger.logit(.debug, message: "Failed to update password for service: \(item.key)")
            }
            
            // For internet passwords - we'll have to loop through this all again
            
            //itemSearch[kSecClass as String ] = kSecClassInternetPassword
        }
    }
    
    func manageKeychainPasswordsInternet(newPassword: String) {
        // get the items to update
        
        myLogger.logit(.debug, message: "Attempting to update keychain internet items.")
        
        let changeItems = prefs.dictionary(for: PrefKeys.keychainItemsInternet)
        var changes = 0
        var changeSecItems = [SecKeychainItem]()
        var changeACLItems = [SecKeychainItem]()
        
        // bail if there's nothing to update
        
        if changeItems?.count == 0 || changeItems == nil {
            myLogger.logit(.debug, message: "No keychain internet items to update.")
            return
        }
        
        let allItems = findAllItems(internetPassword: true)  as! CFArray as Array
        
        if allItems == nil {
            myLogger.logit(.debug, message: "No keychain internet items found.")
            return
        }

        for prefItem in changeItems! {
            
            var noACL = false
            
            let account = (prefItem.value as! String).variableSwap()
            
            if prefItem.key.contains("<<noACL>>") {
                noACL = true
            }
            
            let serverURL = URL.init(string:(prefItem.key).variableSwap())
            
            if prefs.bool(for: PrefKeys.keychainItemsDebug) {
                print("***Item to look for***")
                print(account)
                print(serverURL?.absoluteString as Any)
            }
            
            for item in allItems {
                let itemAccount = (item["acct"] ?? "None")
                let itemService = (item["svce"] ?? "None")
                let itemLabel = (item["labl"] ?? "None")
                let itemRef = (item["v_Ref"] ?? "None")
                let itemPort = (item["port"] ?? "None")
                let itemProtocol = (item["ptcl"] ?? "None")
                let itemServer = (item["srvr"] ?? "None")
                
                if itemServer as? String == serverURL?.host {
                    
                    var fullMatch = true

                    if prefs.bool(for: PrefKeys.keychainItemsDebug) {

                    print("Found potential match...")
                    print("\tChecking for full match...")
                    print("")
                    print("\tKeychain Item account: \(itemAccount as? String ?? "NONE")")
                    print("\tPref item account: \(account)")
                    }
                    
                    if ((itemAccount as? String ?? "ANY").lowercased() == account.lowercased()) || account == "<<ANY>>" {
                        print("\t\tAccount matches")
                    } else {
                        fullMatch = false
                    }
                    
                    if prefs.bool(for: PrefKeys.keychainItemsDebug) {
                    print("")
                    print("\tKeychain Item protocol: \(String(describing: itemProtocol))")
                    print("\tPref item protocol: \(String(describing: serverURL?.scheme))")
                    }
                    
                    if let proto = itemProtocol as? String {
                        if !(proto == getSchemeNumber(scheme: serverURL?.scheme ?? "NONE", proxy: prefItem.key.contains("<<proxy>>"))) {
                            fullMatch = false
                        } else {
                            print("\t\tProtocols match")
                        }
                    } else {
                        print("No protocol set for Keychain item.")
                    }
                    
                    if prefs.bool(for: PrefKeys.keychainItemsDebug) {
                        print("")
                        print("\tKeychain Item port: \(String(describing: itemPort))")
                        print("\tPref Item Port: \(String(describing: serverURL?.port))")
                    }
                    
                    if itemPort as! Int != 0 {
                        if itemPort as? Int ?? 0 == serverURL?.port {
                            print("\t\tPort matches")
                        } else {
                            fullMatch = false
                        }
                    } else {
                        print("No port set, so matching")
                    }
                    
                    if fullMatch {
                        changes += 1
                        if prefs.bool(for: PrefKeys.keychainItemsDebug) {
                            print("***")
                            print("Found a full match")
                            print("***")
                        }
                        changeSecItems.append(itemRef as! SecKeychainItem)
                        
                        if noACL {
                            changeACLItems.append(itemRef as! SecKeychainItem)
                        }

                    }
                }
            }
        }
        
        if prefs.bool(for: PrefKeys.keychainItemsDebug) {
            print("***")
            print("Total matches: \(String(describing: changes))")
        }
        
        if changes > 0 {
            changePasswords(items: changeSecItems, newPassword: newPassword, aclChanges: changeACLItems)
        }
    }
    
    fileprivate func changePasswords(items: [SecKeychainItem], newPassword: String, aclChanges: [SecKeychainItem]? ) {
        
        SecKeychainSetUserInteractionAllowed(false)

        let attrToUpdate: [String:AnyObject] = [
            kSecValueData as String: newPassword.data(using: .utf8) as AnyObject
        ]
        
        var itemSearch: [String:AnyObject] = [
            kSecClass as String: kSecClassInternetPassword as AnyObject,
            kSecMatchLimit as String : kSecMatchLimitAll as AnyObject,
            ]
        
        
        var itemAccess: SecAccess? = nil
        var secApp: SecTrustedApplication? = nil
        var myACLs : CFArray? = nil
        
        for item in items {
            
            var noACL = false
            
            if aclChanges?.contains(item) ?? false {
                noACL = true
            }
            
            itemSearch[kSecValueRef as String ] = item as AnyObject
            
            myErr = SecKeychainItemCopyAccess(item, &itemAccess)
            
            myErr = SecTrustedApplicationCreateFromPath( nil, &secApp)
            
            // Decode ACL
            
            SecAccessCopyACLList(itemAccess!, &myACLs)
            
            var appList: CFArray? = nil
            var desc: CFString? = nil
            
            var prompt = SecKeychainPromptSelector()
            
            for acl in myACLs as! Array<SecACL> {
                SecACLCopyContents(acl, &appList, &desc, &prompt)
                let authArray = SecACLCopyAuthorizations(acl)
                var newACL : SecACL?
                
                if !(authArray as! [String]).contains("ACLAuthorizationPartitionID") && !(authArray as! [String]).contains("ACLAuthorizationExportClear") {
                    continue
                }
                
                if (authArray as! [String]).contains("ACLAuthorizationExportClear") {
                    
                    if noACL {
                        myErr = SecACLSetContents(acl, nil, desc!, prompt)
                    
                        // smack it again to set the ACL
                    
                        myErr = SecKeychainItemSetAccessWithPassword(item, itemAccess!, UInt32(newPassword.count), newPassword)
                    }
                    continue
                }
                
                // pull in the description that's really a functional plist <sigh>
                
                let rawData = Data.init(fromHexEncodedString: desc! as String)
                var format: PropertyListSerialization.PropertyListFormat = .xml
                
                var propertyListObject = try? PropertyListSerialization.propertyList(from: rawData!, options: [], format: &format) as! [ String: [String]]
                
                // add in the team ID that NoMAD is signed with if it doesn't already exist
                
                if !(propertyListObject!["Partitions"]?.contains("teamid:AAPZK3CB24"))! {
                    propertyListObject!["Partitions"]?.append("teamid:AAPZK3CB24")
                }
                
                if prefs.bool(for: PrefKeys.keychainItemsDebug) {
                    myLogger.logit(.debug, message: String(describing: propertyListObject))
                }
                
                // now serialize it back into a plist
                
                let xmlObject = try? PropertyListSerialization.data(fromPropertyList: propertyListObject as Any, format: format, options: 0)
                
                
                myErr = SecKeychainItemSetAccessWithPassword(item, itemAccess!, UInt32(newPassword.count), newPassword)
                
                // now that all ACLs has been adjusted, we can update the item
                
                myErr = SecItemUpdate(itemSearch as CFDictionary, attrToUpdate as CFDictionary)
                
                // now add NoMAD and the original apps back into the property object
                
                myErr = SecACLSetContents(acl, appList, xmlObject!.hexEncodedString() as CFString, prompt)
                
                // smack it again to set the ACL
                
                myErr = SecKeychainItemSetAccessWithPassword(item, itemAccess!, UInt32(newPassword.count), newPassword)
            }
            
            //myErr = SecKeychainItemSetAccessWithPassword(item, itemAccess!, UInt32(newPassword.count), newPassword)
            
            if myErr != 0 {
                myLogger.logit(.base, message: "Error setting keychain ACL.")
            }
        }
        
        SecKeychainSetUserInteractionAllowed(true)

    }
    
    func findAllItems(internetPassword: Bool) -> [AnyObject]? {
        
        var searchReturn: AnyObject? = nil
        var myErr = OSStatus()
        
        var searchTerms : [ String : AnyObject ] = [
            kSecReturnAttributes as String: true as AnyObject,          // return attributes for things we find
            kSecReturnRef as String : true as AnyObject,                // return the SecKeychain reference
            kSecMatchLimit as String : kSecMatchLimitAll as AnyObject   // return all matches
        ]
        
        if internetPassword {
            searchTerms[kSecClass as String] = kSecClassInternetPassword as AnyObject
        } else {
            searchTerms[kSecClass as String] = kSecClassGenericPassword as AnyObject
        }
        
        // Now search for the items
        
        myErr = SecItemCopyMatching(searchTerms as CFDictionary, &searchReturn)
        
        if myErr != 0 {
            print("Error while searching, try different terms.")
            exit(0)
        }
        
        let items = searchReturn as! CFArray as Array
        
        return items
    }
    
    func get4Code(scheme: String, proxy: Bool=false) -> SecProtocolType {
        
        // first see if we're a proxy
        
        if proxy {
            switch scheme {
            case "http":
                return SecProtocolType.httpProxy
            case "https" :
                return SecProtocolType.httpsProxy
            default :
                break
            }
        }
        
        switch scheme {
        case "ftp" :
            return SecProtocolType.FTP
        case "http" :
            return SecProtocolType.HTTP
        case "https" :
            return SecProtocolType.HTTPS
        case "cifs" :
            return SecProtocolType.CIFS
        case "smb" :
            return SecProtocolType.SMB
        default :
            return SecProtocolType.any
        }
    }
    
    func getSchemeNumber(scheme: String, proxy: Bool=false) -> String {
        
        // first see if we're a proxy
        
        if proxy {
            switch scheme {
            case "http":
                return "htpx"
            case "https" :
                return "htsx"
            default :
                break
            }
        }
        
        switch scheme {
        case "ftp" :
            return "ftp"
        case "http" :
            return "http"
        case "https" :
            return "htps"
        case "cifs" :
            return "cifs"
        case "smb" :
            // this needs a trailing space to be a 4Char code <sigh>
            return "smb "
        default :
            return scheme
        }
    }
    
    func createItems(pass: String) {
        
        enum itemPart {
            static let account = "Account"
            static let itemClass = "Class"
            static let label = "Label"
            static let service = "Service"
            static let appPath = "AppPath"
            static let teamID = "TeamID"
        }
        
        // take Dict of item class, item label, account name, item service and Team ID
        
        // read in the pref file
        
        let keyPrefs : UserDefaults? = UserDefaults.init(suiteName: "menu.nomad.keychainitems")
        
        // sanity check the file
        
        if keyPrefs == nil {
            // unable to get prefs
            myLogger.logit(.debug, message: "Failed to read keychain item create preference file.")
            return
        }
        
        if keyPrefs?.integer(forKey: "Version") != 1 {
            // unknown version
            myLogger.logit(.debug, message: "Unknown version of keychain item create file.")
            return
        }
        
        // now check the serial against known good serial
        
        if keyPrefs?.integer(forKey: "Serial") ?? 0 >= prefs.int(for: PrefKeys.keychainItemsCreateSerial) {
            // we've already created this set
            myLogger.logit(.debug, message: "Preference file serial less than or equal to current serial of created items.")
            return
        }
        
        // get dict of items to create
        
        guard let items = keyPrefs?.array(forKey: "Items") as? [Dictionary<String,AnyObject>] else {
            // unable to make dictionary, need to leave
            myLogger.logit(.debug, message: "Unable to make dictionary out of keychain item creation preference")
            return
        }
        
        if items.count < 1 {
            // no items in preference file
            myLogger.logit(.debug, message: "Preference file has no items.")
            return
        }
        
        // now loop through every item
        // 1. ensure enough parts to make the item are there
        // 2. test to see if the item already exists
        // 3. if not make the item
        
        for item in items {
            
            // create an empty search/create dict
            
            var itemAttrs = [ String : AnyObject ]()
            
            // check class
            
            if (item[itemPart.itemClass] as? String ?? "genp") == "genp" {
                
                itemAttrs[kSecAttrType as String] = "genp" as AnyObject
                
                // 1. ensure enough parts to make the item are there
                
                if item[itemPart.account] == nil && item[itemPart.service] == nil {
                    // not enough to make an item
                    myLogger.logit(.debug, message: "Unable to make keychain item, not enough information.")
                    continue
                }
                
                if item[itemPart.account] != nil {
                    let account = (item[itemPart.account] as? String)?.variableSwap() ?? ""
                    itemAttrs[kSecAttrAccount as String] = account as AnyObject
                }
                
                if item[itemPart.service] != nil {
                    let service = (item[itemPart.service] as? String)?.variableSwap() ?? ""
                    itemAttrs[kSecAttrService as String] = service as AnyObject
                }
                
                if item[itemPart.label] != nil {
                    let label = (item[itemPart.label] as? String)?.variableSwap() ?? ""
                    itemAttrs[kSecAttrLabel as String] = label as AnyObject
                }
                
                // add Secure Apps if listed
                
                
            } else {
                // create a generic iternet password "inet"
                
                
            }
            
            // 2. now to check if the item exists
            
            var result : AnyObject? = nil
            var createErr = OSStatus()
            
            createErr = SecItemCopyMatching(itemAttrs as CFDictionary, &result)
            
            if createErr != 0 {
                // item already exists
                
                continue
            }
            
            // 3. create the item
            
            itemAttrs[kSecValueRef as String ] = pass as AnyObject
            
            createErr = SecItemAdd(itemAttrs as CFDictionary, &result)
            
            if createErr != 0 {
                // something went wrong on creating the item
                
                continue
            }
            
            // now to edit the partition ids
            
            if item[itemPart.teamID] != nil {
                
                myLogger.logit(.debug, message: "Adjusting ACL of keychain item \(item[itemPart.label] ?? "" as AnyObject) : \(item[itemPart.account] ?? "" as AnyObject)")
                
                var itemAccess: SecAccess? = nil
                var myACLs : CFArray? = nil
                
                createErr = SecKeychainItemCopyAccess(result as! SecKeychainItem, &itemAccess)
                
                // Decode ACL
                
                SecAccessCopyACLList(itemAccess!, &myACLs)
                
                var appList: CFArray? = nil
                var desc: CFString? = nil
                var prompt = SecKeychainPromptSelector()
                
                for acl in myACLs as! Array<SecACL> {
                    SecACLCopyContents(acl, &appList, &desc, &prompt)
                    let authArray = SecACLCopyAuthorizations(acl)
                    
                    if !(authArray as! [String]).contains("ACLAuthorizationPartitionID") {
                        continue
                    }
                    
                    // pull in the description that's really a functional plist <sigh>
                    
                    let rawData = Data.init(fromHexEncodedString: desc! as String)
                    var format: PropertyListSerialization.PropertyListFormat = .xml
                    
                    var propertyListObject = try? PropertyListSerialization.propertyList(from: rawData!, options: [], format: &format) as! [ String: [String]]
                    
                    // add in the team ID that NoMAD is signed with if it doesn't already exist
                    
                    for teamID in item[itemPart.teamID] as! [String] {
                        if !(propertyListObject!["Partitions"]?.contains(teamID))! {
                            propertyListObject!["Partitions"]?.append(teamID)
                        }
                    }
                    
                    if prefs.bool(for: PrefKeys.keychainItemsDebug) {
                        myLogger.logit(.debug, message: String(describing: propertyListObject))
                    }
                    
                    // now serialize it back into a plist
                    
                    let xmlObject = try? PropertyListSerialization.data(fromPropertyList: propertyListObject as Any, format: format, options: 0)
                    
                    // Hi Rick, how's things?
                    
                    // now add NoMAD and the original apps back into the property object
                    
                    createErr = SecACLSetContents(acl, appList, xmlObject!.hexEncodedString() as CFString, prompt)
                    
                    // smack it again to set the ACL
                    
                    createErr = SecKeychainItemSetAccessWithPassword(myKeychainItem, itemAccess!, UInt32(pass.count), pass)
                }
                
                if createErr != 0 {
                    myLogger.logit(.base, message: "Error setting keychain ACL.")
                }
            }
            
        }
    }
    
    func cleanCerts() {
        
        myLogger.logit(.debug, message: "Beginning cert clean.")
        
        // CLEAN CERTS
        
        if prefs.string(for: PrefKeys.userUPN) == "" {
            // no UPN available
            return
        }
        
        let certListTemp = findAllUserCerts(prefs.string(for: PrefKeys.userUPN)!, defaultNamingContext: "blank" )
        
        if certListTemp == nil {
            
            // no certs, so return
            
            myLogger.logit(.debug, message: "No certs found, so no certs to clean.")
            return
        }
        
        if certListTemp?.count ?? 0 > 0 {
            
            _ = certListTemp?.sorted(by: { $0.expireInt > $1.expireInt })
            
            for i in 0...(certListTemp!.count - 1) {
                
                // delete all but the 2 youngest and the 2 oldest
                
                if i > 1 && ( i < certListTemp!.count - 2 ) {
                    
                    // get SecCert from SecIdentity Ref
                    
                    var certRef : SecCertificate? = nil
                    
                    var myErr = SecIdentityCopyCertificate(certListTemp![i].certRef!, &certRef)
                    
                    // delete cert
                    
                    myLogger.logit(.debug, message: "Deleting cert with expiration: " + String(describing: certListTemp![i].expireDate))
                    if myErr != 0 {
                        let itemAttrs : [String: AnyObject]  = [
                            kSecClass as String: kSecClassCertificate,
                            kSecMatchItemList as String : [ certRef ] as AnyObject,
                            ]
                        
                        myErr = SecItemDelete(itemAttrs as CFDictionary)
                        
                        if myErr != 0 {
                            myLogger.logit(.debug, message: "Error deleting cert.")
                        }
                    }
                    
                    // now for the Key
                    
                    let itemAttrs : [String: AnyObject]  = [
                        kSecClass as String: kSecClassIdentity,
                        kSecMatchItemList as String : [ certListTemp![i].certRef ] as AnyObject,
                        ]
                    
                    myErr = SecItemDelete(itemAttrs as CFDictionary)
                    
                    if myErr != 0 {
                        myLogger.logit(.debug, message: "Error deleting key.")
                    }
                }
            }
        }
    }
}
