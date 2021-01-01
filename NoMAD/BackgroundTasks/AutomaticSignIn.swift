//
//  AutomaticSignIn.swift
//  NoMAD
//
//  Created by Joel Rennich on 12/22/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import NoMAD_ADAuth

public struct NoMAD_SessionUserObject {
    var userPrincipal: String
    var session: NoMADSession
    var aging: Bool
    var expiration: Date?
    var daysToGo: Int?
    var userInfo: ADUserRecord?
}

class AutomaticSignIn {
        
    let workQueue = DispatchQueue(label: "menu.nomad.kerberos", qos: .userInitiated, attributes: [], autoreleaseFrequency: .inherit, target: nil)

    var prefs = PrefManager()
    var nomadAccounts = [NoMADAccount]()
    var workers = [AutomaticSignInWorker]()

    init() {
        loadAccounts()
        signInAllAccounts()
    }
    
    private func loadAccounts() {
        let decoder = PropertyListDecoder.init()
        if let accountsData = prefs.data(for: .accounts),
           let storedAccountsList = try? decoder.decode(NoMADAccounts.self, from: accountsData) {
            self.nomadAccounts = storedAccountsList.accounts
        }
    }
    
    private func signInAllAccounts() {
        let klist = KlistUtil()
        let keyUtil = KeychainUtil()
        let princs = klist.klist().map({ $0.principal })
        let defaultPrinc = klist.defaultPrincipal
        
        workQueue.async {
            for account in self.nomadAccounts {
            if account.keychain && account.automatic {
                let worker = AutomaticSignInWorker(userName: account.upn)
                self.workers.append(worker)
                if princs.contains(where: { $0.lowercased() == account.upn }) {
                    worker.getUserInfo()
                } else {
                    worker.auth()
                }
            }
        }
        }
        cliTask("kswitch -p \(defaultPrinc ?? "")")
    }
}

class AutomaticSignInWorker: NoMADUserSessionDelegate {
    
    var prefs = PrefManager()
    var userName: String
    var session: NoMADSession
    
    init(userName: String) {
        self.userName = userName
        let domain = userName.userDomain()
        self.session = NoMADSession(domain: domain ?? "", user: userName.user())
        self.session.setupSessionFromPrefs(prefs: prefs)
    }
    
    func auth() {
        let keyUtil = KeychainUtil()
        
        do {
            try keyUtil.findPassword(userName.lowercased())
            session.userPass = keyUtil.password
            session.delegate = self
            keyUtil.scrub()
            session.authenticate()
        } catch {
            print("unable to find keychain item for user: \(userName)")
        }
    }
    
    func getUserInfo() {
        cliTask("kswitch -p \(self.session.userPrincipal )")
        session.delegate = self
        session.userInfo()
    }
    
    func NoMADAuthenticationSucceded() {
        print("Auth succeded for user: \(userName)")
        cliTask("kswitch -p \(self.session.userPrincipal )")
        session.userInfo()
    }
    
    func NoMADAuthenticationFailed(error: NoMADSessionError, description: String) {
        print("Auth failed for user: \(userName)")
        print("Error: \(description)")
        switch error {
        case .AuthenticationFailure, .PasswordExpired:
            print("Removing bad password from keychain")
            let keyUtil = KeychainUtil()
            if keyUtil.findAndDelete(self.userName.lowercased()) {
                print("Successfully removed keychain item")
            }
        default:
            break
        }
    }
    
    func NoMADUserInformation(user: ADUserRecord) {
        print("User info: \(user)")
        prefs.setADUserInfo(user: user)
        mainMenu.buildMenu()
    }
}
