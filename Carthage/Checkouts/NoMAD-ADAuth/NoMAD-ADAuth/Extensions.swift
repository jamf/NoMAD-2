//
//  Extensions.swift
//  NoMAD
//
//  Created by Boushy, Phillip on 10/4/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

import Foundation

// bitwise convenience
prefix operator ~~

prefix func ~~(value: Int) -> Bool {
    return (value > 0) ? true : false
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
    
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func containsIgnoringCase(_ find: String) -> Bool {
        return self.range(of: find, options: NSString.CompareOptions.caseInsensitive) != nil
    }
    
    func isBase64() -> Bool {
        if let data = Data(base64Encoded: self),
           let _ = String(data: data, encoding: .utf8) {
            return true
        }
        return false
    }
    
    func base64String() -> String? {
        if self.isBase64() {
            return self
        } else {
            return self.data(using: .utf8)?.base64EncodedString()
        }
    }
    
    func ldapFilterEscaped() -> String {
        self.replacingOccurrences(of: "\\", with: "\\5c").replacingOccurrences(of: "*", with: "\\2a").replacingOccurrences(of: "(", with: "\\28").replacingOccurrences(of: ")", with: "\\29").replacingOccurrences(of: "/", with: "\\2f")
    }
    
    func encodeNonASCIIAsUTF8Hex() -> String {
        var result = ""
        var startingString = self
        
        if self.isBase64() {
            if let data = Data(base64Encoded: self),
               let decodedString = String(data: data, encoding: .utf8) {
                startingString = decodedString
            }
        }
        
        for character in startingString.ldapFilterEscaped() {
            if character.asciiValue != nil {
                result.append(character)
            } else {
                for byte in String(character).utf8 {
                    result.append("\\" + (NSString(format:"%2X", byte) as String))
                }
            }
        }
        return result
    }
}

extension Character {
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.filter{$0.isASCII}.first?.value
    }
}
