//
//  MenuItem.swift
//  NoMAD
//
//  Created by Joel Rennich on 6/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa

class NoMADMenuItem: NSMenuItem {
    
    var hiddenPrefKey: PrefKeys
    var titlePrefKey: PrefKeys
    
    override var isHidden: Bool {
        get {
            UserDefaults.standard.bool(forKey: hiddenPrefKey.rawValue)
        }
        set {
            UserDefaults.standard.set(self, forKey: hiddenPrefKey.rawValue)
        }
    }
    
    override var title: String {
        get {
            UserDefaults.standard.string(forKey: titlePrefKey.rawValue) ?? ""
        }
        set {
            return
        }
    }
    
    init(prefKey: PrefKeys, titlePref: PrefKeys, action: Selector?=nil) {
        self.hiddenPrefKey = prefKey
        self.titlePrefKey = titlePref
        
        super.init(title: "", action: nil, keyEquivalent: "")
        self.action = action
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
