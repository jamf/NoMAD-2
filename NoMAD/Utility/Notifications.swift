//
//  Notifications.swift
//  NoMAD
//
//  Created by Joel Rennich on 6/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation

let kUpdateNotificationName = "menu.nomad.nomad.update"
let updateNotification = Notification(name: Notification.Name(rawValue: "menu.nomad.nomad.update"))

func createNotification(name: String) {

    let notification = Notification(name: Notification.Name(rawValue: name))
    NotificationQueue.default.enqueue(notification, postingStyle: .now)
}
