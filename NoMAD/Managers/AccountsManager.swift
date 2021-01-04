//
//  AccountsManager.swift
//  NoMAD
//
//  Created by Joel Rennich on 1/3/21.
//  Copyright © 2021 Orchard & Grove, Inc. All rights reserved.
//

import Foundation

protocol AccountUpdate {
    func updateAccounts(accounts: [NoMADAccount])
}

class AccountsManager {
    
    var prefs = PrefManager()
    var accounts = [NoMADAccount]()
    var delegates = [AccountUpdate]()
    
    static let shared = AccountsManager()
    
    init() {
        loadAccounts()
    }
    
    private func loadAccounts() {
        let decoder = PropertyListDecoder.init()
        if let accountsData = prefs.data(for: .accounts),
           let accountsList = try? decoder.decode(NoMADAccounts.self, from: accountsData) {
            accounts = accountsList.accounts
        }
        updateDelegates()
    }
    
    func saveAccounts() {
        let encoder = PropertyListEncoder.init()
        if let accountData = try? encoder.encode(NoMADAccounts.init(accounts: accounts))  {
            prefs.set(for: .accounts, value: accountData)
            prefs.sharedDefaults?.setValue(accountData, forKey: PrefKeys.accounts.rawValue)
        }
        updateDelegates()
    }
    
    func addAccount(account: NoMADAccount) {
        accounts.append(account)
        saveAccounts()
    }
    
    func deleteAccount(account: NoMADAccount) {
        accounts.removeAll() { $0 == account }
        saveAccounts()
    }
    
    func accountForPrincipal(principal: String) -> NoMADAccount? {
        
        for account in accounts {
            if account.upn.lowercased() == principal.lowercased() {
                return account
            }
        }
        
        return nil
    }
    
    func returnAllDomains() -> [String] {
        var domains = [String]()
        
        for account in accounts {
            if let userDomain = account.upn.userDomain(),
               !domains.contains(userDomain){
                domains.append(userDomain)
            }
        }
        
        return domains
    }
    
    private func updateDelegates() {
        for delegate in delegates {
            delegate.updateAccounts(accounts: accounts)
        }
    }
}
