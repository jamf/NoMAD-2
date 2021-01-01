
//
//  QuitMenuItme.swift
//  NoMAD
//
//  Created by Joel Rennich on 6/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa

class QuitMenuItem: NSMenuItem {
   var prefs = PrefManager()
    
    override var isHidden: Bool {
        get {
            prefs.bool(for: .hideQuit)
        }
        set {
            return
        }
    }
    
    override var title: String {
        get {
            prefs.string(for: .menuQuit) ?? "Quit"
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
        NSApp.terminate(nil)
    }
}
