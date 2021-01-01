//
//  NetworkWatcher.swift
//  Verify
//
//  Created by Joel Rennich on 1/3/19.
//  Copyright © 2019 Joel Rennich. All rights reserved.
//

import Foundation
import SystemConfiguration

// small class to watch for network changes and send a notification

// singletons

let nw = NetworkWatcher()

var kNetworkUpdatePending = false
var kNetworkUpdateTimer: Timer?

class NetworkWatcher {

    var actions: Array<() -> Void>?

    let changed: SCDynamicStoreCallBack = { dynamicStore, _, _ in

        if kGlobalVerbose {
            print("***Network change***")
        }

        if !kNetworkUpdatePending {
            kNetworkUpdateTimer = Timer.init(timeInterval: 3, repeats: false, block: {_ in
                kNetworkUpdatePending = false
                NotificationQueue.default.enqueue(Notification(name: Notification.Name(rawValue: kNetworkUpdateNotification)), postingStyle: .now)
            })

            RunLoop.main.add(kNetworkUpdateTimer!, forMode: RunLoop.Mode.default)
            kNetworkUpdatePending = true
        }
    }

    func setup() {
        var dynamicContext = SCDynamicStoreContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
        let dcAddress = withUnsafeMutablePointer(to: &dynamicContext, {UnsafeMutablePointer<SCDynamicStoreContext>($0)})

        if let dynamicStore = SCDynamicStoreCreate(kCFAllocatorDefault, "com.jamf.connect.networknotification" as CFString, changed, dcAddress) {
            let keysArray = ["State:/Network/Global/IPv4" as CFString, "State:/Network/Global/IPv6"] as CFArray
            SCDynamicStoreSetNotificationKeys(dynamicStore, nil, keysArray)
            let loop = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, dynamicStore, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), loop, .defaultMode)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(runActions), name: NSNotification.Name(rawValue: kNetworkUpdateNotification), object: nil)
    }

    @objc fileprivate func runActions() {
       _ = defaults.string(forKey: Preferences.ActionNetworkChange.rawValue)?.runAction()
    }
}
