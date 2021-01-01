//
//  ExpirationMenuItem.swift
//  NoMAD
//
//  Created by Joel Rennich on 6/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa
import NoMAD_ADAuth

class ExpirationMenuItem: NSMenuItem {
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
            var dateFormatter = DateFormatter.init()
            dateFormatter.dateStyle = .medium
            if let expireDate = prefs.date(for: .userPasswordExpireDate) {
                return dateFormatter.string(from: expireDate)
            } else {
                return "No Expiration"
            }
        }
        set {
            return
        }
    }
}

