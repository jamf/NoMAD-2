//
//  SignInMenuItem.swift
//  NoMAD
//
//  Created by jcadmin on 9/24/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//


import Foundation
import Cocoa

class SignInMenuItem: NSMenuItem {
    
    var prefs = PrefManager()
    
    override var isHidden: Bool {
        get {
            if prefs.bool(for: PrefKeys.hideSignIn) {
                return true
            } else if prefs.bool(for: .singleUserMode) {
                let klist = KlistUtil()
                if klist.klist().count > 0 {
                    return true
                }
            }
            return false
        }
        set {
            return
        }
    }
    
    override var title: String {
        get {
            prefs.string(for: PrefKeys.menuSignIn) ?? "Sign In..."
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
        
        if mainMenu.authUI == nil {
            mainMenu.authUI = AuthUI()
        }
        
        mainMenu.authUI?.window!.forceToFrontAndFocus(nil)
    }
}
