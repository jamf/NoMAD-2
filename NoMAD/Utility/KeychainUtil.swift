//
//  Keychainutil.swift
//  NoMAD
//
//  Created by jcadmin on 9/25/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation

enum NoMAD2Error: Error {
    case notConnected
    case notLoggedIn
    case noPasswordExpirationTime
    case ldapServerLookup
    case ldapNamingContext
    case ldapServerPasswordExpiration
    case ldapConnectionError
    case userPasswordSetDate
    case userHome
    case noStoredPassword
    case storedPasswordWrong
    case noUsername
}

class KeychainUtil {
    var myErr: OSStatus = 0
    let serviceName = "NoMAD2"
    var passLength: UInt32 = 0
    var passPtr: UnsafeMutableRawPointer?

    var myKeychainItem: SecKeychainItem?
    var password = "********"
    
    let sharedKeychainName = "VRPY9KHGX6.menu.nomad.nomad" //kSecAttrAccessGroup

    func scrub() {
        // overwrite any variables we need to scrub
        password = "*********"
        passPtr?.deallocate()
        passPtr = nil
    }

    // find if there is an existing account password and return it or throw

    func findPassword(_ name: String) throws {

        // clean up anything lingering

        passPtr = nil
        passLength = 0
        
        var searchReturn: AnyObject?
        
        let attrs = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccessGroup : sharedKeychainName,
            kSecAttrAccount: name,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecAttrSynchronizable: kCFBooleanTrue
            ] as [CFString: Any]

        myErr = SecItemCopyMatching(attrs as CFDictionary, &searchReturn)
        
        //myErr = SecKeychainFindGenericPassword(nil, UInt32(serviceName.count), serviceName, UInt32(name.count), name, &passLength, &passPtr, &myKeychainItem)

        if let passData = searchReturn as? Data,
           myErr == OSStatus(errSecSuccess),
           let pass = String(data: passData, encoding: .utf8) {
            
            password = pass
            //password = NSString(bytes: passPtr!, length: Int(passLength), encoding: String.Encoding.utf8.rawValue)! as String
            //return password! as String
            //passPtr = nil
            return
        } else {
            // now check for all lowercase password just in case

            if name == name.lowercased() {
                // already lowercase, no need to check again

                throw NoMAD2Error.noStoredPassword
            }

            myErr = SecKeychainFindGenericPassword(nil, UInt32(serviceName.count), serviceName, UInt32(name.lowercased().count), name.lowercased(), &passLength, &passPtr, &myKeychainItem)

            if myErr == OSStatus(errSecSuccess) {
                password = NSString(bytes: passPtr!, length: Int(passLength), encoding: String.Encoding.utf8.rawValue)! as String
                //return password! as String
                passPtr = nil
                return
            } else {

                // now to look for /anything/ that might match

                var searchReturn: AnyObject?

                let attrs = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrService: serviceName,
                    kSecReturnRef: true,
                    kSecReturnAttributes: true,
                    kSecMatchLimit: kSecMatchLimitAll
                    ] as [CFString: Any]

                myErr = SecItemCopyMatching(attrs as CFDictionary, &searchReturn)

                if myErr != 0 || searchReturn == nil {
                    // no results throw
                    throw NoMAD2Error.noStoredPassword
                }

                let returnDict = searchReturn as! CFArray as Array
                for item in returnDict {
                    if ((item["acct"] as? String ?? "").lowercased() == name.lowercased()) || ((item["acct"] as? String ?? "").lowercased().components(separatedBy: "@").first == name.lowercased().components(separatedBy: "@").first ) {
                        // got a match now let's lookup the password

                        myErr = SecKeychainFindGenericPassword(nil, UInt32(serviceName.count), serviceName, UInt32((item["acct"] as? String ?? "").count), (item["acct"] as? String ?? ""), &passLength, &passPtr, &myKeychainItem)

                        if myErr == OSStatus(errSecSuccess) {
                            password = NSString(bytes: passPtr!, length: Int(passLength), encoding: String.Encoding.utf8.rawValue)! as String
                            passPtr = nil
                            return
                        } else {
                            throw NoMAD2Error.noStoredPassword
                        }
                    }
                }
                throw NoMAD2Error.noStoredPassword
            }
        }
    }



    /// Sets the keychain password for JC: V. If the item already exists it will not be modified.
    ///
    /// - Parameter name: The username to set the password for.
    /// - Returns: A `OSStatus` object containing the result of the keychain operation.
    func setPassword(_ name: String) -> OSStatus {
        
        
        let attributes = [kSecClass: kSecClassGenericPassword,
                          kSecAttrService: serviceName,
                          kSecAttrAccessGroup : sharedKeychainName,
                          kSecAttrAccount: name,
                          kSecAttrSynchronizable: kCFBooleanTrue,
                          kSecValueData: password.data(using: .utf8)] as [String: Any]
        myErr = SecItemAdd(attributes as CFDictionary, nil)
        
        if myErr != noErr {
            print("Unable to set keychain password. Error: \(String(describing: SecCopyErrorMessageString(myErr, nil)))")
        }
        return myErr
    }


    /// Updates the password of an existing Keychain Item.
    ///
    /// - Parameter name: The username to set the password for.
    /// - Returns: `true` if the change succeeds. `false` if not.
    /// To avoid fidling with Keychain SACL on the item we simply delete the existing match and make a new entry.
    @discardableResult func updatePassword(_ name: String) -> Bool {
        var tempStr = password
        if (try? findPassword(name.lowercased())) != nil {
            _ = deletePassword()
        }
        password = tempStr
        tempStr = ""

        myErr = setPassword(name)
        if myErr == OSStatus(errSecSuccess) {
            print("Updated keychain item for NoMAD2.")
            return true
        } else {
            print("Unable to update keychain password.")
            return false
        }
    }

    // delete the password from the keychain
    func deletePassword() -> OSStatus {

        if myKeychainItem == nil {
            return -1
        }

        myErr = SecKeychainItemDelete(myKeychainItem!)
        return myErr
    }

    // convience functions
    func findAndDelete(_ name: String) -> Bool {
        do {
            try findPassword(name.lowercased())
        } catch {
            return false
        }
        if ( deletePassword() == 0 ) {
            return true
        } else {
            return false
        }
    }
}
