//
//  Extensions.swift
//  NoMAD
//
//  Created by Boushy, Phillip on 10/4/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

import Foundation
import Cocoa

extension NSWindow {
    @objc func forceToFrontAndFocus(_ sender: AnyObject?) {
        NSApp.activate(ignoringOtherApps: true)
        self.makeKeyAndOrderFront(sender);
    }
}

extension UserDefaults {
    func sint(forKey defaultName: String) -> Int? {
        
        let defaults = UserDefaults.standard
        let item = defaults.object(forKey: defaultName)
        
        if item == nil {
            return nil
        }
        
        // test to see if it's an Int
        
        if let result = item as? Int {
            return result
        } else {
            // it's a String!
            
            return Int(item as! String)
        }
    }
}

extension String {
    var translate: String {
        //return Localizator.sharedInstance.translate(self)
        self
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func containsIgnoringCase(_ find: String) -> Bool {
        return self.range(of: find, options: NSString.CompareOptions.caseInsensitive) != nil
    }
    
    func safeURLPath() -> String? {
        let allowedCharacters = CharacterSet(bitmapRepresentation: CharacterSet.urlPathAllowed.bitmapRepresentation)
        return addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
    
    func safeURLQuery() -> String? {
        let allowedCharacters = CharacterSet(bitmapRepresentation: CharacterSet.urlQueryAllowed.bitmapRepresentation)
        return addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }

    func safeAddingPercentEncoding(withAllowedCharacters allowedCharacters: CharacterSet) -> String? {
            // using a copy to workaround magic: https://stackoverflow.com/q/44754996/1033581
            let allowedCharacters = CharacterSet(bitmapRepresentation: allowedCharacters.bitmapRepresentation)
            return addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
    
    func variableSwap(_ encoding: Bool=true) -> String {
        
        var cleanString = self
        
        let domain = UserDefaults.standard.string(forKey: PrefKeys.aDDomain.rawValue) ?? ""
        let fullName = UserDefaults.standard.string(forKey: PrefKeys.displayName.rawValue)?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
        let serial = getSerial().addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
        let shortName = UserDefaults.standard.string(forKey: PrefKeys.userShortName.rawValue) ?? ""
        let upn = UserDefaults.standard.string(forKey: PrefKeys.userUPN.rawValue) ?? ""
        let email = UserDefaults.standard.string(forKey: PrefKeys.userEmail.rawValue) ?? ""
        let currentDC = UserDefaults.standard.string(forKey: PrefKeys.aDDomainController.rawValue) ?? "NONE"
        
        if encoding {
            cleanString = cleanString.replacingOccurrences(of: " ", with: "%20") //cleanString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed) ?? cleanString
        }
        
        cleanString = cleanString.replacingOccurrences(of: "<<domain>>", with: domain)
        cleanString = cleanString.replacingOccurrences(of: "<<fullname>>", with: fullName)
        cleanString = cleanString.replacingOccurrences(of: "<<serial>>", with: serial)
        cleanString = cleanString.replacingOccurrences(of: "<<shortname>>", with: shortName)
        cleanString = cleanString.replacingOccurrences(of: "<<upn>>", with: upn)
        cleanString = cleanString.replacingOccurrences(of: "<<email>>", with: email)
        cleanString = cleanString.replacingOccurrences(of: "<<noACL>>", with: "")
        cleanString = cleanString.replacingOccurrences(of: "<<domaincontroller>>", with: currentDC)

        
        // now to remove any proxy settings
        
        cleanString = cleanString.replacingOccurrences(of: "<<proxy>>", with: "")
        
        return cleanString //.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
        
    }
}

extension Data {
    
    init?(fromHexEncodedString string: String) {
        
        // Convert 0 ... 9, a ... f, A ...F to their decimal value,
        // return nil for all other input characters
        func decodeNibble(u: UInt16) -> UInt8? {
            switch(u) {
            case 0x30 ... 0x39:
                return UInt8(u - 0x30)
            case 0x41 ... 0x46:
                return UInt8(u - 0x41 + 10)
            case 0x61 ... 0x66:
                return UInt8(u - 0x61 + 10)
            default:
                return nil
            }
        }
        
        self.init(capacity: string.utf16.count/2)
        var even = true
        var byte: UInt8 = 0
        for c in string.utf16 {
            guard let val = decodeNibble(u: c) else { return nil }
            if even {
                byte = val << 4
            } else {
                byte += val
                self.append(byte)
            }
            even = !even
        }
        guard even else { return nil }
    }
    
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
