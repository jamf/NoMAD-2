//
//  AccountsMenuItem.swift
//  NoMAD
//
//  Created by jcadmin on 9/29/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa

class AccountsMenuItem: NSMenuItem {
    
    var prefs = PrefManager()
    
    override var isHidden: Bool {
        get {
            prefs.bool(for: PrefKeys.hideAccounts) || prefs.bool(for: .singleUserMode)
        }
        set {
            return
        }
    }
    
    override var title: String {
        get {
            prefs.string(for: PrefKeys.menuAccounts) ?? "Accounts..."
        }
        set {
            return
        }
    }
    
    init() {
         super.init(title: "", action: #selector(doAction), keyEquivalent: "")
         self.target = self
     }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func doAction() {
        if mainMenu.accountsUI == nil {
            mainMenu.accountsUI = AccountsUI()
        }
        
        mainMenu.accountsUI?.window!.forceToFrontAndFocus(nil)
    }
}
