//
//  SelfServiceManager.swift
//  NoMAD
//
//  Created by Tom Nook on 11/29/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

import Foundation

/// The software self-service apps that NoMAD can discover.
///
/// - casper: JAMF Software
/// - lanrev: HEAT Software
/// - munki: OpenSource Software
/// - custom: Filesystem path to a self-service app

enum SelfServiceType {
    case casper
    case lanrev
    case munki
    case custom
}

class SelfServiceManager {
    
    var prefs = PrefManager()
    
    /// Checks for several Mac client management agents
    ///
    /// - Returns: A value from `SelfServiceType` enum or nil.
    func discoverSelfService() -> SelfServiceType? {
        
        // first check if a preference has been set:
        
        if prefs.string(for: PrefKeys.selfServicePath) != nil {
            myLogger.logit(.info, message:"Using custom self-service path")
            return .custom
        } else if prefs.string(for: PrefKeys.selfServicePath) == "None" {
            return nil
        }
        
        // now look for any others
        
        let selfServiceFileManager = FileManager.default
        
        if selfServiceFileManager.fileExists(atPath: "/Applications/Self Service.app") {
            myLogger.logit(.info, message:"Using Casper for Self Service")
            return .casper
        }
        if selfServiceFileManager.fileExists(atPath: "/Library/Application Support/LANrev Agent/LANrev Agent.app/Contents/MacOS/LANrev Agent") {
            myLogger.logit(.info, message:"Using LANRev for Self Service")
            return .lanrev
        }
        if selfServiceFileManager.fileExists(atPath: "/Applications/Managed Software Center.app") {
            myLogger.logit(.info, message:"Using Munki for Self Service")
            return .munki
        }
        return nil
    }
}
