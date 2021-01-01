//
//  PrefManager.swift
//  NoMAD
//
//  Created by Joel Rennich on 6/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import NoMAD_ADAuth

let kStateDomain = "menu.nomad.state"
let kSharedDefaultsName = "VRPY9KHGX6.nomad.shared"

extension UserDefaults {
    @objc dynamic var Accounts: Data? {
        return data(forKey: "Accounts")
    }
}

class PrefManager {
    
    let defaults = UserDefaults.standard
    let stateDefaults = UserDefaults.init(suiteName: kStateDomain)
    let sharedDefaults = UserDefaults(suiteName: kSharedDefaultsName)
    
    func array(for prefKey: PrefKeys) -> [Any]? {
        defaults.array(forKey: prefKey.rawValue)
    }
    
    func string(for prefKey: PrefKeys) -> String? {
        defaults.string(forKey: prefKey.rawValue)
    }
    
    func object(for prefKey: PrefKeys) -> Any? {
        defaults.object(forKey: prefKey.rawValue)
    }
    
    func dictionary(for prefKey: PrefKeys) -> [String:Any]? {
        defaults.dictionary(forKey: prefKey.rawValue)
    }
    
    func bool(for prefKey: PrefKeys) -> Bool {
        defaults.bool(forKey: prefKey.rawValue)
    }
    
    func set(for prefKey: PrefKeys, value: Any) {
        defaults.set(value as AnyObject, forKey: prefKey.rawValue)
    }
    
    func int(for prefKey: PrefKeys) -> Int {
        defaults.integer(forKey: prefKey.rawValue)
    }
    
    func date(for prefKey: PrefKeys) -> Date? {
        defaults.object(forKey: prefKey.rawValue) as? Date
    }
    
    func clear(for prefKey: PrefKeys) {
        defaults.set(nil, forKey: prefKey.rawValue)
    }
    
    func data(for prefKey: PrefKeys) -> Data? {
        defaults.data(forKey: prefKey.rawValue)
    }
    
    func setADUserInfo(user: ADUserRecord) {
        defaults.set(user.userPrincipal.lowercased(), forKey: PrefKeys.lastUser.rawValue)
        if user.passwordAging ?? false {
            self.set(for: .userPasswordExpireDate, value: user.computedExireDate as Any)
        } else {
            self.clear(for: .userPasswordExpireDate)
        }
        
        stateDefaults?.set(user.cn, forKey: PrefKeys.userCN.rawValue)
        stateDefaults?.set(user.groups, forKey: PrefKeys.userGroups.rawValue)
        stateDefaults?.set(user.computedExireDate, forKey: PrefKeys.userPasswordExpireDate.rawValue)
        stateDefaults?.set(user.passwordSet, forKey: PrefKeys.userPasswordSetDate.rawValue)
        stateDefaults?.set(user.homeDirectory, forKey: PrefKeys.userHome.rawValue)
        stateDefaults?.set(user.userPrincipal, forKey: PrefKeys.userPrincipal.rawValue)
        stateDefaults?.set(user.customAttributes, forKey: PrefKeys.customLDAPAttributesResults.rawValue)
        stateDefaults?.set(user.shortName, forKey: PrefKeys.userShortName.rawValue)
        stateDefaults?.set(user.upn, forKey: PrefKeys.userUPN.rawValue)
        stateDefaults?.set(user.email, forKey: PrefKeys.userEmail.rawValue)
        stateDefaults?.set(user.fullName, forKey: PrefKeys.userFullName.rawValue)
        stateDefaults?.set(user.firstName, forKey: PrefKeys.userFirstName.rawValue)
        stateDefaults?.set(user.lastName, forKey: PrefKeys.userLastName.rawValue)
        stateDefaults?.set(Date(), forKey: PrefKeys.userLastChecked.rawValue)
        var allUsers = stateDefaults?.dictionary(forKey: PrefKeys.allUserInformation.rawValue) ?? [String:[String:AnyObject]]()
        allUsers[user.userPrincipal] = [
            "CN": user.cn,
            "groups:": user.groups,
            "UserPasswordExpireDate": user.computedExireDate?.description ?? "",
            "UserHome": user.homeDirectory ?? "",
            "UserPrincipal": user.userPrincipal,
            "CustomLDAPAttributesResults": user.customAttributes?.description ?? "",
            "UserShortName": user.shortName,
            "UserUPN": user.upn,
            "UserEmail": user.email ?? "",
            "UserFullName": user.fullName,
            "UserFirstName": user.firstName,
            "UserLastName": user.lastName,
            "UserLastChecked": Date()
        ]
        stateDefaults?.setValue(allUsers, forKey: PrefKeys.allUserInformation.rawValue)
    }
}
