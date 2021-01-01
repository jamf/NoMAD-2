//
//  AboutMenuItem.swift
//  NoMAD
//
//  Created by Joel Rennich on 7/1/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa

class AboutMenuItem: NSMenuItem {
    var prefs = PrefManager()
    
    override var isHidden: Bool {
        get {
            prefs.bool(for: .hideAbout)
        }
        set {
            return
        }
    }
    
    override var title: String {
        get {
            prefs.string(for: .menuAbout) ?? "About..."
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
        welcomeScreen.window!.forceToFrontAndFocus(nil)
    }
}
