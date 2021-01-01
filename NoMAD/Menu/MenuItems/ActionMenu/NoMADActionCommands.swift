//
//  NoMADActionCommands.swift
//  NoMAD
//
//  Created by Joel Rennich on 1/24/18.
//  Copyright © 2018 Orchard & Grove Inc. All rights reserved.
//

import Foundation
import Cocoa

// class to keep all of the possible actions

public enum ActionType {
    case path, app, url, ping, SRV, seperator, alert, notify, file, groups, menuicon
}

    // run an action

public func runActionCommand( action: String, options: String) -> String {

    if CommandLine.arguments.contains("-actions") {
        print("\nAction Command starting...")
        print("Action: \(action)")
        print("OptionRaw: \(options)")
    }
        var result = ""

    if options == "none" {
        return "error"
    }

    let optionsClean = options.variableSwap(false)

    if CommandLine.arguments.contains("-actions") {
            print("Options cleaned: \(optionsClean)")
        }
    
        switch action.lowercased() {
        case "path" :
            result = cliTask(optionsClean)
        case "app" :
            result = runApp(path: optionsClean)
        case "url" :
            NSWorkspace.shared.open(URL.init(string: optionsClean)!)
        case "file" :
            result = FileManager().fileExists(atPath: optionsClean).description
        case "ping" :
            let pingResult = cliTask("/sbin/ping -q -c 4 -t 3 -o " + optionsClean)
            let pingResultParts = pingResult.components(separatedBy: ",")

            for part in pingResultParts {
                if part.contains("packets received") {
                    if part == "0 packets received" {
                        return "false"
                    } else {
                        return "true"
                    }
                }
            }
            return "false"

        case "SRV" :
            // TODO: use SRV lookup class here
            break
        case "adgroup" :
            if (UserDefaults.standard.array(forKey: PrefKeys.groups.rawValue) as! [String]).contains(optionsClean) {
                result = "true"
            } else {
                return "false"
            }
        case "alert" :

            // show an alert only if we have options

            if optionsClean == "" || optionsClean == "false" || optionsClean == "true" {
                break
            }

            let myAlert = NSAlert()
            myAlert.messageText = optionsClean

            // move to the foreground since we're displaying UI

            DispatchQueue.main.async {
                myAlert.runModal()
            }
        case "notify" :

            // show a notification only if we have options

            if optionsClean == "" || optionsClean == "false" || optionsClean == "true" {
                break
            }

            let notification = NSUserNotification()
            notification.informativeText = options
            notification.hasReplyButton = false
            notification.hasActionButton = false
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)

        case "false" :
            return "false"
        case "true" :
            return "true"
        case "menuicon":
                menuIcons.updateIcon(path: options)
        default :
            break
        }
    
    if CommandLine.arguments.contains("-actions") {
        print("Result: \(result)")
    }
        return result
    }


private func runApp(path: String) -> String {
    var editablePath = path
    let backslashCharacter: Character = "/"
    if let character = editablePath.first, character != backslashCharacter {
        editablePath = "/\(path)"
    }
    
    var url = URL.init(fileURLWithPath: editablePath)
    
    if !url.checkFileExist() {
        // file doesn't exist, support differences between macoses
        let systemPath = "/System"
        let applicationPath = "/Applications"
        
        if editablePath.contains(systemPath) {
            // only Catalina is using /System/Applications for default Apps, remove to support older oses
            let oldOSPath = editablePath.replacingOccurrences(of: systemPath, with: "")
            url = URL.init(fileURLWithPath: oldOSPath)
        } else if editablePath.contains(applicationPath) {
            // support Catalina
            let catalinaPath = editablePath.replacingOccurrences(of: applicationPath, with: "\(systemPath)\(applicationPath)")
            url = URL.init(fileURLWithPath: catalinaPath)
        }
    }
    
    let result = try? NSWorkspace.shared.launchApplication(at: url, options: NSWorkspace.LaunchOptions.default, configuration: [:] )
    
    if result == nil {
        return "false"
    }
    return "true"
}
