//
//  UserMenuItem.swift
//  NoMAD
//
//  Created by Joel Rennich on 7/1/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa

class UserMenuItem: NSMenuItem {
    
    var prefs = PrefManager()
    
    override var isHidden: Bool {
        get {
            false
        }
        set {
            return
        }
    }
    
    override var title: String {
        get {
            prefs.string(for: .lastUser) ?? "Not signed in"
        }
        set {
            return
        }
    }
    
    override var toolTip: String? {
        get {
            prefs.string(for: .userUPN)
        }
        set {
            return
        }
    }
}
