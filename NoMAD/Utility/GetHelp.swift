//
//  GetHelp.swift
//  NoMAD
//
//  Created by Joel Rennich on 7/25/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

//
// Class to manage what the Get Help menu option does
//

import Foundation
import Cocoa

//TODO: Move to a standard URL for the Bomgar client so we can use the standard URLSession tools.
class GetHelp {

    var prefs = PrefManager()
    
    func getHelp() {
        if let getHelpType = prefs.string(for: PrefKeys.getHelpType),
            let getHelpOptions = prefs.string(for: PrefKeys.getHelpOptions) {

            if getHelpType.count > 0 && getHelpOptions.count > 0 {
                switch getHelpType {
                case "Bomgar":
                    if let myURL = subVariables(getHelpOptions) {
                        OperationQueue.main.addOperation() {
                            let _ = cliTask("curl -o /tmp/BomgarClient.zip " + myURL )
                            let _ = cliTaskNoTerm("/usr/bin/ditto -kx /tmp/BomgarClient.zip /tmp/")
                            
                            if FileManager.default.fileExists(atPath: "/tmp/Bomgar/Double-Click To Start Support Session.app") {
                            let _ = cliTask("/usr/bin/open /tmp/Bomgar/Double-Click\\ To\\ Start\\ Support\\ Session.app")
                            } else if FileManager.default.fileExists(atPath: "/private/tmp/BeyondTrust Remote Support/Double-Click To Start Support Session.app") {
                                let _ = cliTask("/usr/bin/open /private/tmp/BeyondTrust\\ Remote\\ Support/Double-Click\\ To\\ Start\\ Support\\ Session.app")
                            } else if FileManager.default.fileExists(atPath: "/private/tmp/Open To Start Support Session.app") {
                                let _ = cliTask("/usr/bin/open /private/tmp/Open\\ To\\ Start\\ Support\\ Session.app")
                            }
                        }
                    }
                case "URL":
                        guard let url = URL(string: getHelpOptions) else {
                            myLogger.logit(.base, message: "Could not create help URL.")
                            break
                        }
                        NSWorkspace.shared.open(url)
                case "Path":
                    let _ = cliTask(getHelpOptions.replacingOccurrences(of: " ", with: "\\ "))
                case "App":
                    NSWorkspace.shared.launchApplication(getHelpOptions)
                default:
                    myLogger.logit(.info, message: "Invalid getHelpType or getHelpOptions, defaulting to www.apple.com/support")
                    openDefaultHelpURL()
                }
            } else {
                myLogger.logit(.info, message: "No help options set, defaulting to www.apple.com/support")
                openDefaultHelpURL()
            }
        }
    }

    fileprivate func openDefaultHelpURL() {
        guard let url = URL(string: "http://www.apple.com/support") else {
            myLogger.logit(.base, message: "Could not create default help URL.")
            return
        }
        NSWorkspace.shared.open(url)
    }

    fileprivate func subVariables(_ url: String) -> String? {
        // TODO: get e-mail address as a variable
        var createdURL = url

        guard let domain = prefs.string(for: PrefKeys.aDDomain),
            let fullName = prefs.string(for: PrefKeys.displayName)?.safeURLQuery(),
            let serial = getSerial().safeURLQuery(),
            let shortName = prefs.string(for: PrefKeys.userShortName)
            else {
                myLogger.logit(.base, message: "Could not create Bomgar launch string.")
                return nil
        }
        createdURL = createdURL.replacingOccurrences(of: "<<domain>>", with: domain)
        createdURL = createdURL.replacingOccurrences(of: "<<fullname>>", with: fullName)
        createdURL = createdURL.replacingOccurrences(of: "<<serial>>", with: serial)
        createdURL = createdURL.replacingOccurrences(of: "<<shortname>>", with: shortName)
        return createdURL
    }
}
