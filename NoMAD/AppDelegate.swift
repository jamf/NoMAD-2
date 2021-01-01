//
//  AppDelegate.swift
//  NoMAD
//
//  Created by Joel Rennich on 6/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let prefs = PrefManager()
        mainMenu.statusBarItem.menu = mainMenu.mainMenu
        mainMenu.statusBarItem.isVisible = !prefs.bool(for: .lightsOutIKnowWhatImDoing)
        
        UserDefaults.standard.addObserver(self, forKeyPath: PrefKeys.lightsOutIKnowWhatImDoing.rawValue, options: .new, context: nil)
        
        if !prefs.bool(for: PrefKeys.dontShowWelcome) && ProcessInfo().operatingSystemVersion.minorVersion > 10 {
            welcomeScreen.window?.forceToFrontAndFocus(nil)
        }
        
        BackGroundManager.shared.processAutomaticSignIn()
        print("finished starting up")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == PrefKeys.lightsOutIKnowWhatImDoing.rawValue {
            if let newValue = change?[NSKeyValueChangeKey.newKey] as? Bool {
                mainMenu.statusBarItem.isVisible = !newValue
            }
        }
    }
}

