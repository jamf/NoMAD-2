///
//  MenuIcons.swift
//  NoMAD
//
//  Created by Joel Rennich on 2/3/19.
//  Copyright © 2019 Jamf. All rights reserved.
//

import Foundation
import Cocoa
import os.log

let menuIcons = MenuIcons()

class MenuIcons {
    
    let defaultIconOn = NSImage.init(imageLiteralResourceName: "NoMAD-Caribou-on")
    let defaultIconOff = NSImage.init(imageLiteralResourceName: "NoMAD-Caribou-off")
    let defaultIconOnDark = NSImage.init(imageLiteralResourceName: "NoMAD-Caribou-dark-on")
    let defaultIconOffDark = NSImage.init(imageLiteralResourceName: "NoMAD-Caribou-dark-off")
    
    var customIconOn: NSImage?
    var customIconOff: NSImage?
    var customIconOnDark: NSImage?
    var customIconOffDark: NSImage?
    var defaults = UserDefaults.standard
    
    fileprivate var defaultColor = NSColor.green
    
    init() {
        
        let fm = FileManager.default
        
        if let customOn = defaults.string(forKey: PrefKeys.iconOn.rawValue) {
            if fm.isReadableFile(atPath: customOn) {
                customIconOn = NSImage.init(contentsOfFile: customOn)
                //customIconOn?.size = .init(width: 32.0, height: 32.0)
                defaultColor = NSColor.clear
            }
        }
        
        if let customOff = defaults.string(forKey: PrefKeys.iconOff.rawValue) {
            if fm.isReadableFile(atPath: customOff) {
                customIconOff = NSImage.init(contentsOfFile: customOff)
                defaultColor = NSColor.clear
            }
        }
        
        if let customOnDark = defaults.string(forKey: PrefKeys.iconOnDark.rawValue) {
            if fm.isReadableFile(atPath: customOnDark) {
                customIconOnDark = NSImage.init(contentsOfFile: customOnDark)
                defaultColor = NSColor.clear
            }
        }
        
        if let customOffDark = defaults.string(forKey: PrefKeys.iconOffDark.rawValue) {
            if fm.isReadableFile(atPath: customOffDark) {
                customIconOffDark = NSImage.init(contentsOfFile: customOffDark)
                defaultColor = NSColor.clear
            }
        }
        
        DistributedNotificationCenter.default.addObserver(self, selector: #selector(interfaceModeChanged), name: NSNotification.Name(rawValue: "AppleInterfaceThemeChangedNotification"), object: nil)
    }
    
    @objc func interfaceModeChanged() {
        // Dark/Light mode change, check for which one to use
        mainMenu.statusBarItem.image = currentIcon()
    }
    
    func currentIcon(activeIcon: Bool?=nil) -> NSImage {
        
        
        //if (ticketsItem.state == .on && activeIcon == nil) || activeIcon ?? false {
        if  activeIcon ?? false {
            if UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?["AppleInterfaceStyle"] == nil {
                return customIconOn ?? defaultIconOn
            } else {
                return customIconOnDark ?? defaultIconOnDark
            }
        } else {
            if UserDefaults.standard.persistentDomain(forName: UserDefaults.globalDomain)?["AppleInterfaceStyle"] == nil {
                return customIconOff ?? defaultIconOff
            } else {
                return customIconOffDark ?? defaultIconOffDark
            }
        }
    }
    
    func updateIcon(path: String) {
        
        for pathchange in ["-on", "-off", "-on-dark", "-off-dark"] {
            var newPath = path.replacingOccurrences(of: "-on", with: pathchange)
            if !FileManager.default.isReadableFile(atPath: newPath) {
                newPath = path
            }
            
                switch pathchange {
                case "-on":
                    customIconOn = NSImage.init(contentsOfFile: newPath)
                    defaultColor = NSColor.clear
                case "-off":
                    customIconOff = NSImage.init(contentsOfFile: newPath)
                    defaultColor = NSColor.clear
                case "-on-dark":
                    customIconOnDark = NSImage.init(contentsOfFile: newPath)
                    defaultColor = NSColor.clear
                case "-off-dark":
                    customIconOffDark = NSImage.init(contentsOfFile: newPath)
                    defaultColor = NSColor.clear
                default:
                    break
                }
        }
        createNotification(name: kUpdateNotificationName)
    }
    
    fileprivate func returnColor(color: String) -> NSColor {
        switch color.lowercased() {
        case "green" :
            return NSColor.green
        case "red" :
            return NSColor.red
        case "yellow" :
            return NSColor.yellow
        case "black" :
            return NSColor.black
        case "blue" :
            return NSColor.blue
        case "purple" :
            return NSColor.purple
        case "white" :
            return NSColor.white
        case "orange" :
            return NSColor.orange
        case "brown" :
            return NSColor.brown
        case "grey" :
            return NSColor.gray
        case "pink" :
            return NSColor.systemPink
        case "none" :
            return NSColor.clear
        default :
            return defaultColor
        }
    }
}

func validateImage(path: String) -> NSImage? {

    let fm = FileManager.default
    if fm.fileExists(atPath: path) {
        return NSImage.init(contentsOfFile: path)
    }
    return nil
}
