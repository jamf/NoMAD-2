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
        signInAllAccounts()
    }
    
    private func signInAllAccounts() {
        let klist = KlistUtil()
        let princs = klist.klist().map({ $0.principal })
        let defaultPrinc = klist.defaultPrincipal
        self.workers.removeAll()
        
            for account in AccountsManager.shared.accounts {
                if account.automatic {
                    workQueue.async {
                        let worker = AutomaticSignInWorker(userName: account.upn)
                        worker.checkUser()
                        self.workers.append(worker)
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
    var resolver = SRVResolver()
    let domain: String
    
    init(userName: String) {
        self.userName = userName
        domain = userName.userDomain() ?? ""
        self.session = NoMADSession(domain: domain, user: userName.user())
        self.session.setupSessionFromPrefs(prefs: prefs)
    }
    
    func checkUser() {
        
        let klist = KlistUtil()
        let princs = klist.klist().map({ $0.principal })
        
        resolver.resolve(query: "_ldap._tcp." + domain.lowercased(), completion: { i in
            print("SRV Response for: \("_ldap._tcp." + self.domain)")
            switch i {
            case .success(let result):
                if result.SRVRecords.count > 0 {
                    if princs.contains(where: { $0.lowercased() == self.userName }) {
                    self.getUserInfo()
                } else {
                    self.auth()
                }
                } else {
                    print("No SRV Records found")
                }
            case .failure(let error):
                print("No DNS results for domain \(self.domain), unable to automatically login. Error: \(error)")
            }
        })
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
