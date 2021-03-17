//
//  AuthenticationViewController.swift
//  nomadssoe
//
//  Created by jcadmin on 12/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Cocoa
import AuthenticationServices
import SecurityInterface.SFCertificatePanel
import CryptoTokenKit

class AuthenticationViewController: NSViewController {

    var authorizationRequest: ASAuthorizationProviderExtensionAuthorizationRequest?
    
    @IBOutlet weak var logo: NSImageView!
    @IBOutlet weak var cancelButton: NSButton!
    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSTextField!
    @IBOutlet weak var username: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var accountList: NSPopUpButton!
    @IBOutlet weak var signInButton: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var certButton: NSButton!
    
    var cardInserted: Bool {
        get {
            for token in tkWatcher.tokenIDs {
                if token.containsIgnoringCase("pivtoken") {
                    return true
                }
            }
            return false
        }
    }
    
    var running = false
    
    let tkWatcher = TKTokenWatcher()
    
    var prefs = PrefManager()
    var nomadAccounts = [NoMADAccount]()
    let myWorkQueue = DispatchQueue(label: "menu.nomad.kerberos", qos: .userInteractive, attributes:[], autoreleaseFrequency: .never, target: nil)

    override func loadView() {
        super.loadView()
        // Do any additional setup after loading the view.
        self.view.window?.makeKeyAndOrderFront(nil)
        self.view.wantsLayer = true
        buildAccountsMenu()
        accountList.action = #selector(popUpChange)
        accountList.target = self
        startWatching()
        certButton.isHidden = !cardInserted
        certButton.isEnabled = cardInserted
    }

    @IBAction func clickSignIn(_ sender: Any) {
        startOperations()
                
                if self.accountList.isHidden {
                    let kerbHelper = KerbHelper()
                    startOperations()
                    if kerbHelper.signIn(user: username.stringValue, pass: password.stringValue) {
                        stopOperations()
                        authorizationRequest?.doNotHandle()
                    } else {
                        stopOperations()
                    }
                } else if PKINIT.shared.cardInserted {
                    if let currentUser = self.accountList.selectedItem?.title,
                       let certs = PKINIT.shared.returnCerts() {
                        for account in nomadAccounts {
                            if account.upn == currentUser || account.displayName == currentUser {
                                for cert in certs {
                                    if account.pubkeyHash == cert.pubKeyHash {
                                        let pin = self.password.stringValue
                                        var error = ""
                                        PKINIT.shared.running = true
                                        myWorkQueue.async {
                                            error = PKINIT.shared.authWithCert(identity: cert.identity, user: currentUser, pin: pin)
                                            if error == "" {
                                                self.authorizationRequest?.doNotHandle()
                                            } else {
                                                self.stopOperations()
                                                print("Kerberos error: \(error)")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    for account in nomadAccounts {
                        if account.displayName == self.accountList.selectedItem?.title  {
                            let kerbHelper = KerbHelper()
                            startOperations()
                            if kerbHelper.signIn(user: account.upn, pass: password.stringValue) {
                                stopOperations()
                                authorizationRequest?.doNotHandle()
                            } else {
                                stopOperations()
                            }
                        }
                    }
                }
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        authorizationRequest?.doNotHandle()
    }
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("AuthenticationViewController")
    }
    
    private func startWatching() {
        tkWatcher.setInsertionHandler({ token in
            myLogger.logit(.debug, message: "Token inserted: \(token)")
            RunLoop.main.perform {
                self.buildAccountsMenu()
            }
            self.tkWatcher.addRemovalHandler({ token in
                print("Token removed: \(token)")
                RunLoop.main.perform {
                    self.buildAccountsMenu()
                }
            }, forTokenID: token)
        })
    }
    
    private func buildAccountsMenu() {
            
            if PKINIT.shared.cardInserted,
               let certs = PKINIT.shared.returnCerts() {
                self.accountList.removeAllItems()
                
                for cert in certs {
                    let account = NoMADAccount(displayName: cert.cn, upn: cert.principal ?? cert.cn, keychain: false, automatic: false, pubkeyHash: cert.pubKeyHash)
                    self.nomadAccounts.append(account)
                    self.accountList.addItem(withTitle: cert.principal ?? cert.cn)
                }
                self.accountList.isHidden = false
                self.username.isHidden = true
                self.accountList.isEnabled = true
                self.passwordField.stringValue = "PIN"
                self.password.stringValue = ""
                popUpChange()
                self.accountList.becomeFirstResponder()
                self.accountList.becomeFirstResponder()
                return
            }
            
            self.passwordField.stringValue = "Password"
            let decoder = PropertyListDecoder.init()
        if let accountsData = prefs.sharedDefaults?.data(forKey: PrefKeys.accounts.rawValue),
               let storedAccountsList = try? decoder.decode(NoMADAccounts.self, from: accountsData) {
                self.accountList.removeAllItems()
                self.nomadAccounts = storedAccountsList.accounts
                for account in storedAccountsList.accounts {
                    self.accountList.addItem(withTitle: account.displayName)
                }
                self.accountList.isHidden = false
                self.accountList.isEnabled = true
                self.username.isHidden = true
                self.password.becomeFirstResponder()
                popUpChange()
                return
            }
            self.username.isHidden = false
        self.username.becomeFirstResponder()
        }
    
    @objc func popUpChange() {
           
           if PKINIT.shared.cardInserted {
               return
           }
           
           for account in nomadAccounts {
               if account.displayName == self.accountList.selectedItem?.title {
                   if account.keychain {
                       let keyUtil = KeychainUtil()
                       do {
                           try keyUtil.findPassword(account.upn.lowercased())
                           RunLoop.main.perform {
                               self.password.stringValue = keyUtil.password
                               keyUtil.scrub()
                           }
                           return
                       } catch {
                           print("Unable to get password")
                       }
                   }
               }
           }
           
           RunLoop.main.perform {
               self.password.stringValue = ""
           }
       }
    
    fileprivate func startOperations() {
        RunLoop.main.perform {
            self.spinner.startAnimation(nil)
            self.signInButton.isEnabled = false
        }
    }
    
    fileprivate func stopOperations() {
        RunLoop.main.perform {
            self.spinner.stopAnimation(nil)
            self.signInButton.isEnabled = true
        }
    }
}

extension AuthenticationViewController: ASAuthorizationProviderExtensionAuthorizationRequestHandler {
    
    public func beginAuthorization(with request: ASAuthorizationProviderExtensionAuthorizationRequest) {
        self.authorizationRequest = request

                // Call this to indicate immediate authorization succeeded.
                //let authorizationHeaders = [String: String]() // TODO: Fill in appropriate authorization headers.
                //request.complete(httpAuthorizationHeaders: authorizationHeaders)
               
                // Or present authorization view and call self.authorizationRequest.complete() later after handling interactive authorization.
                
                let kerbHelper = KerbHelper()
                
                if let klist = kerbHelper.oldKlist(),
                   let tickets = klist.tickets {
                    
                    for ticket in tickets {
                        if ticket.principal.contains(request.realm) {
                            request.doNotHandle()
                        }
                    }
                }
                
                 request.presentAuthorizationViewController(completion: { (success, error) in
                    if error != nil {
                        request.doNotHandle()
                    }
                 })
            }
}

extension AuthenticationViewController: PKINITCallbacks {
    func cardChange() {
        RunLoop.main.perform {
            self.buildAccountsMenu()
            self.certButton.isHidden = !self.cardInserted
            self.certButton.isEnabled = self.cardInserted
        }
    }
}
