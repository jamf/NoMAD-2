//
//  NoMADSession+BuildWithPrefs.swift
//  NoMAD
//
//  Created by Joel Rennich on 12/27/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import NoMAD_ADAuth

extension NoMADSession {
    
    func setupSessionFromPrefs(prefs: PrefManager) {
        self.useSSL = prefs.bool(for: .lDAPoverSSL)
        self.anonymous = prefs.bool(for: .ldapAnonymous)
        self.customAttributes = prefs.array(for: .customLDAPAttributes) as? [String]
        self.ldapServers = prefs.array(for: .lDAPServerList) as? [String]
    }
}
