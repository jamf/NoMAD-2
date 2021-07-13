//
//  BackgroundManager.swift
//  NoMAD
//
//  Created by Joel Rennich on 12/22/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation

class BackGroundManager {
    
    var automaticSignIn: AutomaticSignIn?
    
    static var shared = BackGroundManager()
    
    // timers
    
    var accountCheckTimer: Timer?
    
    init() {
        setupAutomaticSignIn()
        PKINIT.shared.startWatching()
        nw.setup()
    }
    
    @objc func processAutomaticSignIn() {
            self.automaticSignIn = AutomaticSignIn()
    }
    
    private func setupAutomaticSignIn() {
        accountCheckTimer = Timer(timeInterval: ( 15 * 60 ), target: self, selector: #selector(processAutomaticSignIn), userInfo: nil, repeats: true)
        guard self.accountCheckTimer != nil else { return }
        RunLoop.main.add(accountCheckTimer!, forMode: RunLoop.Mode.common)
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(processAutomaticSignIn), name: "CCAPICCacheChangedNotification" as CFString as NSNotification.Name, object: nil)

    }
}
