//
//  Date.swift
//  NoMAD
//
//  Created by jcadmin on 9/24/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation

extension Date {
    
    var daysToGo: Int? {
        get {
            if self.timeIntervalSinceNow > 0 {
                return Int(self.timeIntervalSinceNow / 60 / 60 / 24)
            } else {
                return nil
            }
        }
    }
}
