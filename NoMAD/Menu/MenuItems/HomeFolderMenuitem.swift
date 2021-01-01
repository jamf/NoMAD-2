//
//  HomeFolderMenuItem.swift
//  NoMAD
//
//  Created by Joel Rennich on 9/24/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//


import Foundation
import Cocoa

class HomeFolderMenuItem: NSMenuItem {
    
    var prefs = PrefManager()
    
    override var isHidden: Bool {
        get {
            
            if let homeURL = prefs.stateDefaults?.string(forKey: PrefKeys.userHome.rawValue) as? String {
                
            }
            
            return prefs.bool(for: .showHome)
        }
        set {
            return
        }
    }
    
    override var title: String {
        get {
            prefs.string(for: PrefKeys.menuHomeDirectory) ?? "Home Directory..."
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
    }
}
