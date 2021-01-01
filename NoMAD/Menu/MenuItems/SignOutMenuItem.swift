//
//  SignInMenuItem.swift
//  NoMAD
//
//  Created by Joel Rennich on 9/24/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//


import Foundation
import Cocoa

class SignOutMenuItem: NSMenuItem {
    
    var prefs = PrefManager()
    
    override var isHidden: Bool {
        get {
            let klist = KlistUtil()
            
            if klist.klist().count == 0 {
                return true
            }
            
            return prefs.bool(for: .hideSignOut)
        }
        set {
            return
        }
    }
    
    override var title: String {
        get {
            prefs.string(for: PrefKeys.menuSignOut) ?? "Sign Out..."
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
        cliTask("/usr/bin/kdestroy")
        mainMenu.buildMenu()
    }
}
