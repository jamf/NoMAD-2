//
//  MainMenu.swift
//  NoMAD
//
//  Created by Joel Rennich on 6/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa

// needs to be a singleton so it doesn't get reaped
let mainMenu = MainMenu()

class MainMenu: NSObject, NSMenuDelegate {
        
    var mainMenu: NSMenu
    var menuOpen = false // is the menu open?
    var menuBuilt: Date? // last time menu was built
    var prefs = PrefManager()
    
    let statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    // Windows
    
    var authUI: AuthUI?
    var accountsUI: AccountsUI?
    
    override init() {
        mainMenu = NSMenu()
        super.init()
        nActionMenu.load()
        nActionMenu.updateActions(true, blocking: true)
        nActionMenu.createMenu()
        buildMenu()
        self.statusBarItem.menu = mainMenu
        UserDefaults.standard.addObserver(self, forKeyPath: PrefKeys.actionItemOnly.rawValue, options: .new, context: nil)
    }
    
    func buildMenu() {
        
        if menuOpen { return }
        
        menuBuilt = Date()
        mainMenu.removeAllItems()
        
        if prefs.bool(for: .actionItemOnly) {
            //mainMenu = nActionMenu.actionMenu
            RunLoop.main.perform {
                self.statusBarItem.button?.image = nActionMenu.menuIcon
                self.statusBarItem.button?.title = nActionMenu.menuText ?? "NoMAD2"
                self.statusBarItem.menu = nActionMenu.actionMenu
            }
            return
        }
        
        // Run through the menu items
        mainMenu.addItem(UserMenuItem())
        mainMenu.addItem(ExpirationMenuItem())
        mainMenu.addItem(SignInMenuItem())
        mainMenu.addItem(SignOutMenuItem())
        mainMenu.addItem(TicketsMenuItem())
        
        // Actions Menu
        
        let actionMenu = NSMenuItem()
        actionMenu.title = "Actions"
        actionMenu.submenu = nActionMenu.actionMenu
        actionMenu.title = nActionMenu.menuText ?? "Actions"
        actionMenu.image = nActionMenu.menuIcon
        if nActionMenu.actionMenu.items.count > 0 {
            mainMenu.addItem(actionMenu)
        }
        
        // Share Mounter Menu
        
        // Get Software + Help
        mainMenu.addItem(NSMenuItem.separator())
        mainMenu.addItem(SelfServiceMenuItem())
        //mainMenu.addItem(GetHelpMenuItem())
        mainMenu.addItem(NSMenuItem.separator())
        mainMenu.addItem(AccountsMenuItem())
        mainMenu.addItem(PreferencesMenuItem())
        mainMenu.addItem(AboutMenuItem())
        mainMenu.addItem(QuitMenuItem())
        
        
        // make changes to the UI here within this RunLoop
        
        RunLoop.main.perform {
            self.statusBarItem.button?.image = menuIcons.currentIcon()
            self.statusBarItem.title = self.statusItemTitle()
            self.statusBarItem.menu = self.mainMenu
        }
    }
    
    // Factory method to build menu items

    fileprivate func buildMenuItem(title: String, tip: String, action: Selector?) -> NSMenuItem {

        let item = NSMenuItem()
        item.title = title
        item.toolTip = tip
        item.isEnabled = true
        if action != nil {
            item.action = action
            item.target = self
        }
        return item
    }
    
    // Selectors for each menu item, note this need to be @objc

    
    //MARK: NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        menuOpen = true
    }
    
    func menuDidClose(_ menu: NSMenu) {
        menuOpen = false
        RunLoop.main.perform {
            self.buildMenu()
        }
    }
    
    @objc fileprivate func buildMenuThrottle() {

        // don't rebuild the menu if it's been built in the last 3 seconds
        // otherwise we can get into a loop

        if (menuBuilt?.timeIntervalSinceNow ?? 0 ) < -3 {
            buildMenu()
        }
    }
    
    private func statusItemTitle() -> String? {
        if let days = self.prefs.date(for: .userPasswordExpireDate)?.daysToGo {
            return "\(days)d"
        } else {
            return "NoMAD2"
        }
    }
}

extension MainMenu {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == PrefKeys.actionItemOnly.rawValue {
            buildMenu()
        }
    }
}
