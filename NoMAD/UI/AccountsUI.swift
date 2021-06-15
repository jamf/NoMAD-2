//
//  Accounts.swift
//  NoMAD
//
//  Created by jcadmin on 9/25/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation
import Cocoa
import SecurityInterface.SFCertificatePanel

class AccountsUI: NSWindowController, NSWindowDelegate {
    
    var prefs = PrefManager()
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
        AccountsManager.shared.delegates.append(self)
        accountTable.delegate = self
        accountTable.dataSource = self
        accountTable.reloadData()
        certButton.isHidden = !PKINIT.shared.cardInserted
        PKINIT.shared.delegates.append(self)
        accountTable.target = self
        //accountTable.doubleAction = #selector(tableViewDoubleClick)
    }
    
    func windowWillClose(_ notification: Notification) {
        mainMenu.accountsUI = nil
    }
    
    @IBAction func addRow(_ sender: Any) {
        AccountsManager.shared.accounts.append(NoMADAccount(displayName: "", upn: "", keychain: false, automatic: false))
        AccountsManager.shared.saveAccounts()
    }
    
    @IBAction func removeRow(_ sender: Any) {
        if accountTable.selectedRow > -1 {
            AccountsManager.shared.accounts.remove(at: accountTable.selectedRow)
        }
        AccountsManager.shared.saveAccounts()
    }
    
    @IBAction func editDisplayName(_ sender: NSTextField) {
        guard accountTable.selectedRow > -1 else { return }
        AccountsManager.shared.accounts[accountTable.selectedRow].displayName = sender.stringValue
        AccountsManager.shared.saveAccounts()
    }
    
    @IBAction func editUPN(_ sender: NSTextField) {
        guard accountTable.selectedRow > -1 else { return }
        AccountsManager.shared.accounts[accountTable.selectedRow].upn = sender.stringValue
        AccountsManager.shared.saveAccounts()
    }
    
    @IBAction func certButton(_ sender: Any) {
        if let certs = PKINIT.shared.returnCerts() {
            let certsMapped = certs.map({$0.cert})
            let panel = SFCertificatePanel()
            panel.beginSheet(for: self.window!, modalDelegate: nil, didEnd: nil, contextInfo: nil, certificates: certsMapped, showGroup: false)
             }
         }
    
    @IBAction func showPicker(_ sender: Any) {
        showIDPicker()
    }
    
    @objc func tableViewDoubleClick(_ sender:AnyObject) {
        print(sender)
    }
}

extension AccountsUI: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        AccountsManager.shared.accounts.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let user = AccountsManager.shared.accounts[row]
        
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
                } else if column.identifier.rawValue == "pubkey" {
                    cellView.textField?.stringValue = user.pubkeyHash ?? ""
                    //cellView.textField?.addSubview(makeCertPickerButton(row: row))
                } else {
                    cellView.textField?.stringValue = user.displayName
                }
                return cellView
            }
        }
        return nil
    }
    
    private func makeCertPickerButton(row: Int) -> NSButton {
        let button = NSButton()
        button.setButtonType(.momentaryPushIn)
        button.frame = NSRect(x: 0, y: 0, width: 100, height: 15)
        button.title = "Pick Cert"
        button.tag = row
        
        button.action = #selector(showIDPicker)
        return button
    }
    
    @objc func showIDPicker() {
        let picker = SFChooseIdentityPanel()
        picker.setAlternateButtonTitle("Cancel")
        if let certs = PKINIT.shared.returnCerts() {
        let mapped = certs.map({$0.cert})
            picker.beginSheet(for: self.window!, modalDelegate: nil, didEnd: nil, contextInfo: nil, identities: mapped, message: "Choose an identity for this account")
        }
    }
    
    private func makeButton(state: Bool, row: Int, type: ButtonType) -> NSButton {
        let checkBox = NSButton()
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
        AccountsManager.shared.accounts[sender.tag].keychain.toggle()
        AccountsManager.shared.saveAccounts()
    }
    
    @objc func toggleAutomatic(_ sender: NSButton) {
        print("changing row: \(sender.tag.description) and column: auto")
        AccountsManager.shared.accounts[sender.tag].automatic.toggle()
        AccountsManager.shared.saveAccounts()
    }
    
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        
        guard let text = object as? String else { return }
        switch tableColumn?.identifier.rawValue {
        case "display":
            AccountsManager.shared.accounts[row].displayName = text
        case "upn":
            AccountsManager.shared.accounts[row].upn = text
        default:
            print("other change")
        }
        AccountsManager.shared.saveAccounts()
    }
}

extension AccountsUI: PKINITCallbacks {
    func cardChange() {
        RunLoop.main.perform {
            self.certButton.isHidden = !PKINIT.shared.cardInserted
            let cols = self.accountTable.tableColumns
            cols.last?.isHidden = !PKINIT.shared.cardInserted
        }
    }
}

extension AccountsUI: AccountUpdate {
    
    func updateAccounts(accounts: [NoMADAccount]) {
        RunLoop.main.perform {
            self.accountTable.reloadData()
        }
    }
}
