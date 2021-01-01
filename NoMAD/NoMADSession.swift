//
//  NoMADSession.swift
//  NoMAD
//
//  Created by Joel Rennich on 6/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import NoMAD_ADAuth

class NoMADSessionManager {
   
    var session: NoMADSession?
    
    init(domain: String, user: String) {
        session = NoMADSession.init(domain: domain, user: user)
    }
}

extension NoMADSessionManager: NoMADUserSessionDelegate {
    
    func NoMADAuthenticationSucceded() {
        session?.userInfo()
    }
    
    func NoMADAuthenticationFailed(error: NoMADSessionError, description: String) {
    }
    
    func NoMADUserInformation(user: ADUserRecord) {

    }
    
    
}
