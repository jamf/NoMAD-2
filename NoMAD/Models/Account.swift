//
//  Account.swift
//  NoMAD
//
//  Created by jcadmin on 9/29/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation

struct NoMADAccount: Codable, Equatable {    
    var displayName: String
    var upn: String
    var keychain: Bool
    var automatic: Bool
    var pubkeyHash: String?
}

struct NoMADAccounts: Codable {
    var accounts: [NoMADAccount]
}
