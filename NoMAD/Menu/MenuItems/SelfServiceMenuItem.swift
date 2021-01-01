//
//  SelfServiceMenuItem.swift
//  NoMAD
//
//  Created by Joel Rennich on 6/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa

class SelfServiceMenuItem: NSMenuItem {
    var selfService = SelfServiceManager()
    var prefs = PrefManager()
    
    override var isHidden: Bool {
        get {
            if prefs.bool(for: .hideGetSoftware) {
                return true
            }
            return (selfService.discoverSelfService() == nil) ? true : false
        }
        set {
            return
        }
    }
    
    override var title: String {
        get {
            prefs.string(for: .menuGetSoftware) ?? "Get Software"
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
        switch selfService.discoverSelfService() {
        case .casper:
            NSWorkspace.shared.launchApplication("/Applications/Self Service.app")
        case .lanrev:
            let _ = cliTask("/Library/Application\\ Support/LANrev\\ Agent/LANrev\\ Agent.app/Contents/MacOS/LANrev\\ Agent --ShowOnDemandPackages")
        case .munki:
            NSWorkspace.shared.launchApplication("/Applications/Managed Software Center.app")
        case .custom:
            if let path = prefs.string(for: PrefKeys.selfServicePath) {
                let _ = cliTask("/usr/bin/open " + path)
            } else {
                myLogger.logit(.debug, message: "Error getting Get Software path")
            }
        case .none:
            myLogger.logit(.base, message: "No Self Service found")
        }
    }
}
