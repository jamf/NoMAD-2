//
//  KerbHelper.swift
//  nomadssoe
//
//  Created by Joel Rennich on 12/29/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import GSS
import os

struct KerbTicket {
    let principal: String
    let expiration: Date
}

extension KerbTicket: CustomStringConvertible {
    
    var description: String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        df.locale = Locale.current
        return "Principal: \(principal), Expires: \(df.string(from: expiration))"
    }
}

struct JSONTicket: Codable {
    let issued, expires, principal: String

    enum CodingKeys: String, CodingKey {
        case issued = "Issued"
        case expires = "Expires"
        case principal = "Principal"
    }
}

struct JSONPrincipal: Codable {
    let version: Int
    let cache, principal: String
    let tickets: [JSONTicket]?
}

struct JSONKlist: Codable {
    let version: Int
    let tickets: [JSONPrincipal]?
}

class KerbHelper {
    
    var min_stat: OM_uint32 = 0
    var mech = __gss_krb5_ccache_name_x_oid_desc
    
    func iterateKerbersCredentials() -> [KerbTicket] {
        
        var tickets = [KerbTicket]()
        
        var outName: UnsafePointer<Int8>?
        let result = gss_krb5_ccache_name(&min_stat, nil, &outName)
        let sema = DispatchSemaphore(value: 0)
        
        gss_iter_creds(&min_stat, 0, &mech, { a, cred in
            
            guard let unwrappedCred = cred else {
                print("end of creds")
                sema.signal()
                return
            }
            
            print("evaluating cred")
            var min_stat: OM_uint32 = 0
            if var name = GSSCredentialCopyName(unwrappedCred),
               let displayName = GSSNameCreateDisplayString(name) {
                let expiration = GSSCredentialGetLifetime(unwrappedCred)
                let expirationDate = Date().addingTimeInterval(TimeInterval(expiration))
                let newTicket = KerbTicket(principal: displayName.takeRetainedValue() as String, expiration: expirationDate)
                tickets.append(newTicket)
            } else {
                print("ticket has expired, removing")
                var tempCred = cred
                gss_destroy_cred(&min_stat, &tempCred!)
                print(min_stat)
            }
        })
        return tickets
    }
    
    func signIn(user: String, pass: String) -> Bool {
        var cred: gss_cred_id_t? = gss_cred_id_t(bitPattern: 1)
        let name = GSSCreateName(user as CFTypeRef, &__gss_c_nt_user_name_oid_desc, nil)
        var err: Unmanaged<CFError>?
        
        let attrs: [String:AnyObject] = [
            kGSSICPassword: pass as AnyObject
        ]
        
        let major = gss_aapl_initial_cred(name!, &__gss_krb5_mechanism_oid_desc, attrs as CFDictionary, &cred!, &err)
        
        if err == nil {
            return true
        }
        return false
    }
    
    func oldKlist() -> JSONKlist? {
        let tickets = cliTask("klist -A --json") //.filter { !$0.isWhitespace}
        if let ticketsData = tickets.data(using: .utf8) {
            return try? JSONDecoder().decode(JSONKlist.self, from: ticketsData)
        }
        return nil
    }
}
