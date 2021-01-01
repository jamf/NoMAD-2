//
//  ActionsMenuItem.swift
//  NoMAD
//
//  Created by Joel Rennich on 6/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa

class ActionsMenuItem: NSMenuItem {
    let nomadActions = NoMADActionMenu()
    
    override var isHidden: Bool {
        get {
            nomadActions.actionMenu.items.count == 0 ? true : false
        }
        set {
            return
        }
    }
}
