//
//  Welcome.swift
//  NoMAD
//
//  Created by Joel Rennich on 7/2/17.
//  Copyright © 2017 NoMAD. All rights reserved.
//

import Foundation
import Cocoa
import WebKit

let welcomeScreen = Welcome()

class Welcome: NSWindowController, NSWindowDelegate {
    
    @IBOutlet weak var welcomeWindow: NSView!
    
    @IBOutlet weak var webView: WebView!
    @IBOutlet weak var versionField: NSTextField!
    @IBOutlet weak var dontShowWelcome: NSButton!
    
    @objc override var windowNibName: NSNib.Name {
        return NSNib.Name("Welcome")
    }
    
    var prefs = PrefManager()
    
    override func windowDidLoad() {
        // set the version number
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        versionField.stringValue = "Version: " + shortVersion
        
        welcomeWindow.window?.title = "Welcome to " + ((Bundle.main.bundlePath.components(separatedBy: "/").last?.replacingOccurrences(of: ".app", with: "")) ?? "NoMAD" )
        
        if prefs.bool(for: PrefKeys.dontShowWelcomeDefaultOn) {
            dontShowWelcome.state = NSControl.StateValue(rawValue: 1)
            prefs.set(for: PrefKeys.dontShowWelcome, value: true)
        }
        
        // Setting the welcome splash screen
        do {
            var customSplashPath : URL
            var customSplashDir : URL
            var customSplashFile : String
            
            if prefs.object(for: PrefKeys.menuWelcome) != nil {
                
                myLogger.logit(.debug, message: "Attempting to load custom welcome splash screen.")

                // Loading the users custom view
                
                // check for trailing / and add if necessary
                
                var customSplash = prefs.object(for: PrefKeys.menuWelcome) as! String
                
                if customSplash.last != "/" {
                    customSplash += "/"
                }
                
                myLogger.logit(.debug, message: "loading: " + customSplash)
                
                customSplashPath =  URL.init(fileURLWithPath: customSplash + "index.html")
                customSplashDir = URL.init(fileURLWithPath: customSplash)
                
                customSplashFile = try String(contentsOf: customSplashPath, encoding: String.Encoding.utf8)
                
            } else {
                
                // Using the default view
                customSplashPath = Bundle.main.url(forResource: "WelcomeSplash", withExtension: "html")!
                customSplashDir = customSplashPath
                customSplashFile = try String(contentsOf: customSplashPath, encoding: String.Encoding.utf8)
            }
            
            // Displaying it out to the webview

            myLogger.logit(.debug, message: "Using Default display method due to older OSX version.")
            //let customSplashFile = try String(contentsOf: customSplashPath, encoding: String.Encoding.utf8)
            
            webView.mainFrame.loadHTMLString(customSplashFile, baseURL: customSplashDir)
        } catch {
            myLogger.logit(.debug, message: "Error reading contents of file")
            return
        }
    }
    
    func windowWillClose(_ notification: Notification) {
        prefs.set(for: PrefKeys.firstRunDone, value: true)
    }
    
    @IBAction func clickDone(_ sender: Any) {
        self.window?.close()
    }
    
}
