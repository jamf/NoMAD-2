//
//  TicketsMenuItem.swift
//  NoMAD
//
//  Created by jcadmin on 9/29/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa

class TicketsMenuItem: NSMenuItem {
    
    var klist = KlistUtil()
    var prefs = PrefManager()
    var ticketMenu = NSMenu()
    
    override var isHidden: Bool {
        get {
            klist.klist()
            return klist.tickets.count < 2
        }
        set {
            return
        }
    }
    
    override var title: String {
        get {
            prefs.string(for: PrefKeys.menuTickets) ?? "Tickets..."
        }
        set {
            return
        }
    }
    
    init() {
        super.init(title: "", action: nil, keyEquivalent: "")
        self.target = self
        ticketMenu.removeAllItems()
        let tickets = klist.klist()
        for ticket in tickets {
            ticketMenu.addItem(withTitle: ticket.principal, action: #selector(changeDefaultPrincipal), keyEquivalent: "")
            ticketMenu.item(withTitle: ticket.principal)?.target = self
            ticketMenu.item(withTitle: ticket.principal)?.toolTip = ticket.expiration.description(with: Locale.current)
            if ticket.principal == klist.defaultPrincipal {
                ticketMenu.item(withTitle: ticket.principal)?.state = NSControl.StateValue(rawValue: 1)
            }
        }
        self.submenu = ticketMenu
     }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func doAction() {
    }
    
    @objc func changeDefaultPrincipal(_ sender: NSMenuItem) {
        _ = cliTask("/usr/bin/kswitch -p " + sender.title)
        RunLoop.main.perform {
            for menuItem in self.ticketMenu.items {
                if menuItem == sender {
                    menuItem.state = NSControl.StateValue(rawValue: 1)
                } else {
                    menuItem.state = NSControl.StateValue(rawValue: 0)
                }
            }
        }
    }
}
