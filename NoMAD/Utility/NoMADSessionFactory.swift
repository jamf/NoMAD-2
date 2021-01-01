//
//  NoMADSessionFactory.swift
//  NoMAD
//
//  Created by jcadmin on 9/24/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import NoMAD_ADAuth

struct NoMADSessionFactory {
    
    var prefs = PrefManager()
    var session: NoMADSession
    
    init(user: String, domain: String) {
        session = NoMADSession.init(domain: domain, user: user)
        session.customAttributes = prefs.array(for: .customLDAPAttributes) as? [String]
        session.recursiveGroupLookup = prefs.bool(for: .recursiveGroupLookup)
        session.ldapServers = prefs.array(for: .lDAPServerList) as? [String]
        session.useSSL = prefs.bool(for: .lDAPoverSSL)
    }
}
