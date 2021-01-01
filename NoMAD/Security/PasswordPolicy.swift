//
//  PasswordPolicy.swift
//  NoMAD Pro
//
//  Created by Joel Rennich on 5/5/17.
//  Copyright © 2017 NoMAD. All rights reserved.
//

import Foundation

// password policy

private let caps: Set<Character> = Set("ABCDEFGHIJKLKMNOPQRSTUVWXYZ")
private let lowers: Set<Character> = Set("abcdefghijklmnopqrstuvwxyz")
private let numbers: Set<Character> = Set("1234567890")
private let symbols: Set<Character> = Set("!\"@#$%^&*()_-+={}[]|:;<>,.?~`\\/")
private var passwordPolicy = [String : AnyObject ]()

private var minLength: String = "0"
private var minUpperCase: String = "0"
private var minLowerCase: String = "0"
private var minNumber: String = "0"
private var minSymbol: String = "0"
private var minMatches: String = "0"

struct complexityPolicy {
    var minLength: Int
    var minUpperCase: Int
    var minLowerCase: Int
    var minNumber: Int
    var minSymbol: Int
    var minMatches: Int
    var excludeUsername: Bool
}

class PasswordPolicy {

    var policyObject = complexityPolicy(minLength: 0, minUpperCase: 0, minLowerCase: 0, minNumber: 0, minSymbol: 0, minMatches: 0, excludeUsername: false)

    init(policy: [AnyHashable: Any]? ) {

        for item in policy! {

            print(item)

            switch item.key as! String {
            case "minLength" :
                policyObject.minLength = Int(item.value as! String)!
            case "minUpperCase" :
                policyObject.minUpperCase = Int(item.value as! String)!
            case "minLowerCase" :
                policyObject.minLowerCase = Int(item.value as! String)!
            case "minNumber" :
                policyObject.minNumber = Int(item.value as! String)!
            case "minSymbol" :
                policyObject.minSymbol = Int(item.value as! String)!
            case "minMatches" :
                policyObject.minMatches = Int(item.value as! String)!
            case "excludeUsername" :
                policyObject.excludeUsername = Bool(item.value as! String)!
            default:
                myLogger.logit(.debug, message: "Unable to set password policy: \(item.key)")
            }
        }
    }

    // safety functions

    func checkPolicy() {

    }

    func checkPassword(pass: String, username: String="") -> String {

        var result = ""

        let capsOnly = String(pass.filter({ (caps.contains($0))}))
        let lowerOnly = String(pass.filter({ (lowers.contains($0))}))
        let numberOnly = String(pass.filter({ (numbers.contains($0))}))
        let symbolOnly = String(pass.filter({ (symbols.contains($0))}))

        var totalMatches = 0

        if pass.count < policyObject.minLength {
            result.append("Length requirement not met.\n")
        }

        if capsOnly.count < policyObject.minUpperCase {
            result.append("Upper case character requirement not met.\n")
        } else {
            totalMatches += 1
        }

        if lowerOnly.count < policyObject.minLowerCase {
            result.append("Lower case character requirement not met.\n")
        } else {
            totalMatches += 1
        }

        if numberOnly.count < policyObject.minNumber {
            result.append("Numeric character requirement not met.\n")
        } else {
            totalMatches += 1
        }

        if symbolOnly.count < policyObject.minSymbol {
            result.append("Symbolic character requirement not met.\n")
        } else {
            totalMatches += 1
        }

        if totalMatches >= policyObject.minMatches && policyObject.minMatches != 0 && pass.count >= policyObject.minLength {
            result = ""
        }

        if policyObject.excludeUsername && pass.contains(username) {
            result.append("Password can not contain user name.")
        }

        return result
    }


}
