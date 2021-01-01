//
//  AuthUI.swift
//  Verify
//
//  Created by Joel Rennich on 11/11/18.
//  Copyright © 2018 Joel Rennich. All rights reserved.
//

import Foundation
import Cocoa
import NoMAD_ADAuth
import SecurityInterface.SFCertificatePanel
import os.log

class AuthUI: NSWindowController, NSWindowDelegate {
    
    @IBOutlet weak var userLabel: NSTextField!
    @IBOutlet weak var passwordLabel: NSTextField!
    
    @IBOutlet weak var userName: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var signInButton: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var logo: NSImageView!
    @IBOutlet weak var changePasswordButton: NSButton!
    @IBOutlet weak var helpButton: NSButton!
    @IBOutlet weak var infoText: NSTextField!
    @IBOutlet weak var accountsList: NSPopUpButton!
    
    var now = Date.init()
    var persistantTimer: Timer?
    var helpURL: String?
    var prefs = PrefManager()
    var nomadAccounts = [NoMADAccount]()
    
    var session: NoMADSession?
    
    let myWorkQueue = DispatchQueue(label: "menu.nomad.kerberos", qos: .userInteractive, attributes:[], autoreleaseFrequency: .never, target: nil)
    
    @objc override var windowNibName: NSNib.Name {
        return NSNib.Name("AuthUI")
    }
    
    override func windowDidLoad() {
        window?.title = prefs.string(for: .windowSignIn) ?? "Sign In"
        buildAccountsMenu()
        accountsList.action = #selector(popUpChange)
        PKINIT.shared.delegates.append(self)
        
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) {
            self.keyDown(with: $0)
            return $0
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        self.stopOperations()
        self.session = nil
        mainMenu.authUI = nil
    }
    
    override func keyDown(with event: NSEvent) {
        
        switch event.charactersIgnoringModifiers {
        case "c":
            if let currentUser = self.accountsList.selectedItem?.title,
               let certs = PKINIT.shared.returnCerts() {
                for account in nomadAccounts {
                    if account.upn == currentUser || account.displayName == currentUser {
                        for cert in certs {
                            if account.pubkeyHash == cert.pubKeyHash {
                                let panel = SFCertificatePanel()
                                panel.beginSheet(for: self.window!, modalDelegate: nil, didEnd: nil, contextInfo: nil, certificates: [cert.cert], showGroup: true)
                            }
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    @IBAction func clickSignIn(_ sender: Any) {
        print("Starting Auth")
        startOperations()
        
        if self.accountsList.isHidden {
            self.session = NoMADSession.init(domain: self.prefs.string(for: .aDDomain) ?? "", user: self.userName.stringValue)
            session?.setupSessionFromPrefs(prefs: prefs)
            session?.userPass = password.stringValue
            session?.delegate = self
            myWorkQueue.async {
                self.session?.authenticate()
            }
        } else if PKINIT.shared.cardInserted {
            if let currentUser = self.accountsList.selectedItem?.title.replacingOccurrences(of: " ◀︎", with: ""),
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
                                        RunLoop.main.perform {
                                            self.window?.title = "Getting User Information"
                                        }
                                        self.session = NoMADSession(domain: currentUser.userDomain() ?? "", user: currentUser.user())
                                        self.session?.setupSessionFromPrefs(prefs: self.prefs)
                                        cliTask("kswitch -p \(self.session?.userPrincipal ?? "")")
                                        self.session?.userInfo()
                                    } else {
                                        print("Kerberos error: \(error)")
                                        RunLoop.main.perform {
                                            self.stopOperations()
                                            self.showAlert(message: error ?? "Unknown Kerberos error")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            for account in nomadAccounts {
                if account.displayName == self.accountsList.selectedItem?.title.replacingOccurrences(of: " •", with: ""),
                   let domain = account.upn.userDomain() {
                    self.session = NoMADSession.init(domain: domain, user: account.upn.user())
                    session?.setupSessionFromPrefs(prefs: prefs)
                    session?.userPass = password.stringValue
                    session?.delegate = self
                    myWorkQueue.async {
                        self.session?.authenticate()
                    }
                }
            }
        }
    }
    
    @IBAction func clickChange(_ sender: Any) {
        
    }
    
    @IBAction func clickHelp(_ sender: Any) {
        
    }
    
    // MARK: Utility functions
    
    private func buildAccountsMenu() {
        
        let klist = KlistUtil()
        let tickets = klist.klist()
        
        if PKINIT.shared.cardInserted,
           let certs = PKINIT.shared.returnCerts() {
            self.accountsList.removeAllItems()
            
            for cert in certs {
                let account = NoMADAccount(displayName: cert.cn, upn: cert.principal ?? cert.cn, keychain: false, automatic: false, pubkeyHash: cert.pubKeyHash)
                self.nomadAccounts.append(account)
                if tickets.contains(where: { $0.principal == cert.principal }) {
                    self.accountsList.addItem(withTitle: (cert.principal ?? cert.cn) + " ◀︎")
                } else {
                    self.accountsList.addItem(withTitle: cert.principal ?? cert.cn)
                }
            }
            self.accountsList.isHidden = false
            self.accountsList.isEnabled = true
            self.passwordLabel.stringValue = "PIN"
            self.password.stringValue = ""
            popUpChange()
            return
        }
        
        self.passwordLabel.stringValue = "Password"
        let decoder = PropertyListDecoder.init()
        if let accountsData = prefs.data(for: .accounts),
           let storedAccountsList = try? decoder.decode(NoMADAccounts.self, from: accountsData) {
            self.accountsList.removeAllItems()
            self.nomadAccounts = storedAccountsList.accounts
            for account in storedAccountsList.accounts {
                if tickets.contains(where: { $0.principal.lowercased() == account.upn.lowercased()}) {
                    self.accountsList.addItem(withTitle: account.displayName + " ◀︎")
                } else {
                    self.accountsList.addItem(withTitle: account.displayName)
                }
            }
            self.accountsList.addItem(withTitle: "Other...")
            self.accountsList.isHidden = false
            self.accountsList.isEnabled = true
            popUpChange()
            return
        }
        
        accountsList.isHidden = true
    }
    
    @objc func popUpChange() {
        
        if self.accountsList.selectedItem?.title == "Other..." {
            setupOther()
        }
        
        if PKINIT.shared.cardInserted {
            return
        }
        
        for account in nomadAccounts {
            if account.displayName == self.accountsList.selectedItem?.title {
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
    
    @objc private func setupOther() {
        RunLoop.main.perform {
            self.accountsList.isHidden = true
        }
    }
    
    fileprivate func startOperations() {
        RunLoop.main.perform {
            self.spinner.startAnimation(nil)
            self.signInButton.isEnabled = false
            self.window?.title = "Authenticating"
        }
    }
    
    fileprivate func stopOperations() {
        RunLoop.main.perform {
            self.spinner.stopAnimation(nil)
            self.signInButton.isEnabled = true
            self.window?.title = self.prefs.string(for: .windowSignIn) ?? "Sign In"
        }
    }
    
    fileprivate func success() {
        
    }
    
    fileprivate func failure(_ message: String? = nil) {
        
    }
    
    private func closeWindow() {
        RunLoop.main.perform {
            self.window?.close()
        }
    }
    
    private func showAlert(message: String) {
        let alert = NSAlert()
        
        var text = message
        
        if message.contains("unable to reach any KDC in realm") {
            text = "Unable to reach any Kerberos servers in this domain. Please check your network connection and try again."
        } else if message.contains("Client") && text.contains("unknown") {
            text = "Your username could not be found. Please check the spelling and try again."
        } else if message.contains("RSA private encrypt failed") {
            text = "Your PIN is incorrect"
        }
        switch message {
        case "Preauthentication failed" :
            text = "Incorrect username or password."
        case "Password has expired" :
            text = "Password has expired."
        default:
            break
        }
        alert.messageText = text
        RunLoop.main.perform {
            if let window = self.window {
                alert.beginSheetModal(for: window, completionHandler: nil)
            }
        }
    }
    
}

extension AuthUI: NoMADUserSessionDelegate {
    
    func NoMADAuthenticationSucceded() {
        print("Auth succeded")
        cliTask("kswitch -p \(self.session?.userPrincipal ?? "")")
        RunLoop.main.perform {
            self.window?.title = "Getting User Information"
        }
        for account in nomadAccounts {
            if account.upn.lowercased() == session?.userPrincipal.lowercased(),
               account.keychain {
                let keyUtil = KeychainUtil()
                RunLoop.main.perform {
                    keyUtil.password = self.password.stringValue
                    if keyUtil.updatePassword(account.upn.lowercased()) {
                        print("Password updated in keychain")
                    }
                    keyUtil.scrub()
                }
            }
        }
        session?.userInfo()
    }
    
    func NoMADAuthenticationFailed(error: NoMADSessionError, description: String) {
        print("Auth failed")
        
        for account in nomadAccounts {
            if account.upn.lowercased() == session?.userPrincipal.lowercased(),
               account.keychain {
                let keyUtil = KeychainUtil()
                if keyUtil.findAndDelete(account.upn.lowercased()) {
                    print("Password removed from Keychain")
                }
            }
        }
        stopOperations()
        showAlert(message: description)
    }
    
    func NoMADUserInformation(user: ADUserRecord) {
        print("User info: \(user)")
        
        // back to the foreground to change the UI
        RunLoop.main.perform {
            self.prefs.setADUserInfo(user: user)
            self.stopOperations()
            mainMenu.buildMenu()
            self.closeWindow()
        }
    }
}

extension AuthUI: PKINITCallbacks {
    func cardChange() {
        RunLoop.main.perform {
            self.buildAccountsMenu()
        }
    }
}
