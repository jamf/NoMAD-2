//
//  String.swift
//  NoMAD
//
//  Created by jcadmin on 9/25/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation

extension String {
    func userDomain() -> String? {
        if self.components(separatedBy: "@").count > 1 {
            return self.components(separatedBy: "@").last
        }
        return nil
    }
    
    func user() -> String {
        self.components(separatedBy: "@").first ?? ""
    }
}
