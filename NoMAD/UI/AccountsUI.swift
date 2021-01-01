//
//  Accounts.swift
//  NoMAD
//
//  Created by jcadmin on 9/25/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa

class AccountsUI: NSWindowController, NSWindowDelegate {
    
    var prefs = PrefManager()
    var accounts = [NoMADAccount]()
    var observer: NSKeyValueObservation?
    
    enum ButtonType {
        case keychain, auto
    }
    
    @IBOutlet weak var accountTable: NSTableView!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    @IBOutlet weak var certButton: NSButton!
    
    @objc override var windowNibName: NSNib.Name {
        return NSNib.Name("AccountsUI")
    }
    
    override func windowDidLoad() {
        loadAccounts()
        accountTable.delegate = self
        accountTable.dataSource = self
        accountTable.reloadData()
        certButton.isHidden = !PKINIT.shared.cardInserted
        PKINIT.shared.delegates.append(self)
        observer = UserDefaults.standard.observe(\.Accounts, options: [.initial, .new], changeHandler: { defaults, change in
            print("Accounts changed, reloading")
            self.reload()
        })
    }
    
    func windowWillClose(_ notification: Notification) {
        mainMenu.accountsUI = nil
        saveAccounts()
    }
    
    private func loadAccounts() {
        let decoder = PropertyListDecoder.init()
        if let accountsData = prefs.data(for: .accounts),
           let accountsList = try? decoder.decode(NoMADAccounts.self, from: accountsData) {
            accounts = accountsList.accounts
        }
    }
    
    private func saveAccounts() {
        let encoder = PropertyListEncoder.init()
        if let accountData = try? encoder.encode(NoMADAccounts.init(accounts: accounts))  {
            prefs.set(for: .accounts, value: accountData)
            prefs.sharedDefaults?.setValue(accountData, forKey: PrefKeys.accounts.rawValue)
        }
    }
    
    @IBAction func addRow(_ sender: Any) {
        accounts.append(NoMADAccount(displayName: "", upn: "", keychain: false, automatic: false))
        accountTable.reloadData()
    }
    
    @IBAction func removeRow(_ sender: Any) {
        if accountTable.selectedRow > 0 {
            accounts.remove(at: accountTable.selectedRow - 1)
        }
        accountTable.reloadData()
    }
    
    @IBAction func editDisplayName(_ sender: NSTextField) {
        guard accountTable.selectedRow > -1 else { return }
        accounts[accountTable.selectedRow].displayName = sender.stringValue
    }
    
    @IBAction func editUPN(_ sender: NSTextField) {
        guard accountTable.selectedRow > -1 else { return }
        accounts[accountTable.selectedRow].upn = sender.stringValue
    }
    
    @objc private func reload() {
        loadAccounts()
        RunLoop.main.perform {
            self.accountTable.reloadData()
        }
    }

}

extension AccountsUI: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        accounts.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let user = accounts[row]
        
        if let column = tableColumn {
            if let cellView = tableView.makeView(withIdentifier: column.identifier, owner: self) as? NSTableCellView  {
                
                if column.identifier.rawValue == "display" {
                    cellView.textField?.stringValue = user.displayName
                } else if column.identifier.rawValue == "upn" {
                    cellView.textField?.stringValue = user.upn
                } else if column.identifier.rawValue == "keychain" {
                    cellView.textField?.stringValue = ""
                    cellView.textField?.addSubview(makeButton(state: user.keychain, row: row, type: .keychain))
                } else if column.identifier.rawValue == "automatic" {
                    cellView.textField?.stringValue = ""
                    cellView.textField?.addSubview(makeButton(state: user.automatic, row: row, type: .auto))
                } else {
                    cellView.textField?.stringValue = user.displayName
                }
                return cellView
            }
        }
        return nil
    }
    
    private func makeButton(state: Bool, row: Int, type: ButtonType) -> NSButton {
        var checkBox = NSButton()
        checkBox.setButtonType(.switch)
        checkBox.frame = NSRect(x: 0, y: 0, width: 40, height: 15)
        checkBox.title = ""
        checkBox.tag = row
        
        switch type {
        case .auto:
            checkBox.action = #selector(toggleAutomatic)
        case .keychain:
            checkBox.action = #selector(toggleKeychain)
        }
        
        if state {
            checkBox.state = .on
        } else {
            checkBox.state = .off
        }
        
        return checkBox
    }
    
    @objc func toggleKeychain(_ sender: NSButton) {
        print("changing row: \(sender.tag.description) and column: keychain")
        accounts[sender.tag].keychain.toggle()
        saveAccounts()
    }
    
    @objc func toggleAutomatic(_ sender: NSButton) {
        print("changing row: \(sender.tag.description) and column: auto")
        accounts[sender.tag].automatic.toggle()
        saveAccounts()
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        
        guard let text = object as? String else { return }
        switch tableColumn?.identifier.rawValue {
        case "display":
            accounts[row].displayName = text
        case "upn":
            accounts[row].upn = text
        default:
            print("other change")
        }
        saveAccounts()
    }
}

extension AccountsUI: PKINITCallbacks {
    func cardChange() {
        RunLoop.main.perform {
            self.certButton.isHidden = !PKINIT.shared.cardInserted
        }
    }
}
