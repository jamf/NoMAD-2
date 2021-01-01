//
//  PasswordChange.swift
//  NoMAD
//
//  Created by Joel Rennich on 7/25/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

//
// Class to manage what the Password Change menu option does
// Mostly cloned from the GetHelp class
//

import Foundation

class PasswordChange {

    func passwordChange() {
        if let passwordChangeType = defaults.string(forKey: Preferences.changePasswordType),
            let passwordChangeOptions = defaults.string(forKey: Preferences.changePasswordOptions) {
            switch passwordChangeType {
            case "Task":
                let result = cliTask(passwordChangeOptions)
                myLogger.logit(.base, message: result)
            case "URL":
                guard let myURL = subVariables(passwordChangeOptions) else {
                    myLogger.logit(.base, message: "Could not create password change URL.")
                    break
                }
                guard let url = URL(string: myURL) else {
                    myLogger.logit(.base, message: "Could not create password change NSURL.")
                    break
                }
                NSWorkspace.shared.open(url)
            case "App":
                let _ = cliTask("/usr/bin/open " + passwordChangeOptions.replacingOccurrences(of: " ", with: "\\ ") )
            case "None":
                myLogger.logit(.base, message: "No password changes allowed.")
            default:
                guard let url = URL(string: "http://www.apple.com/support") else {
                    myLogger.logit(.base, message: "Could not create default support URL.")
                    break
                }
                NSWorkspace.shared.open(url)
            }
        } else {
            myLogger.logit(.debug, message: "Invalid PasswordChangeType or PasswordChangeOptions, defaulting to change via Kerberos.")
        }
    }

    fileprivate func subVariables(_ url: String) -> String? {
        // TODO: get e-mail address as a variable
        var createdURL = url
        if let domain = defaults.string(forKey: Preferences.aDDomain) {
            createdURL = createdURL.replacingOccurrences(of: "<<domain>>", with: domain)
        }

        guard let domain = defaults.string(forKey: Preferences.aDDomain),
            let fullName = defaults.string(forKey: Preferences.displayName)?.safeURLQuery(),
            let serial = getSerial().safeURLQuery(),
            let shortName = defaults.string(forKey: Preferences.userShortName)
            else {
                myLogger.logit(.base, message: "Could not create password change URL.")
                return nil
        }
        createdURL = createdURL.replacingOccurrences(of: "<<domain>>", with: domain)
        createdURL = createdURL.replacingOccurrences(of: "<<fullname>>", with: fullName)
        createdURL = createdURL.replacingOccurrences(of: "<<serial>>", with: serial)
        createdURL = createdURL.replacingOccurrences(of: "<<shortname>>", with: shortName)
        return createdURL
    }
}
