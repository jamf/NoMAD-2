//
//  PrefKeys.swift
//  NoMAD
//
//  Created by Joel Rennich on 6/30/20.
//  Copyright © 2020 Orchard & Grove, Inc. All rights reserved.
//

import Foundation

enum PrefKeys: String, CaseIterable {
    
    typealias RawValue = String
    
    case accounts = "Accounts"
    case actionItemOnly = "ActionItemOnly"
    case aDDomain = "ADDomain"
    case aDSite = "ADSite"
    case aDDomainController = "ADDomainController"
    case allowEAPOL = "AllowEAPOL"
    case allUserInformation = "AllUserInformation"
    case autoAddAccounts = "AutoAddAccounts"
    case autoConfigure = "AutoConfigure"
    case autoRenewCert = "AutoRenewCert"
    case changePasswordCommand = "ChangePasswordCommand"
    case changePasswordType = "ChangePasswordType"
    case changePasswordOptions = "ChangePasswordOptions"
    case caribouTime = "CaribouTime"
    case cleanCerts = "CleanCerts"
    case configureChrome = "ConfigureChrome"
    case configureChromeDomain = "ConfigureChromeDomain"
    case customLDAPAttributes = "CustomLDAPAttributes"
    case customLDAPAttributesResults = "CustomLDAPAttributesResults"
    case deadLDAPKillTickets = "DeadLDAPKillTickets"
    case displayName = "DisplayName"
    case dontMatchKerbPrefs = "DontMatchKerbPrefs"
    case dontShowWelcome = "DontShowWelcome"
    case dontShowWelcomeDefaultOn = "DontShowWelcomeDefaultOn"
    case exportableKey = "ExportableKey"
    case firstRunDone = "FirstRunDone"
    case getCertAutomatically = "GetCertificateAutomatically"
    case getHelpType = "GetHelpType"
    case getHelpOptions = "GetHelpOptions"
    case groups = "Groups"
    case hicFix = "HicFix"
    case hideAbout = "HideAbout"
    case hideAccounts = "HideAccounts"
    case hideExpiration = "HideExpiration"
    case hideExpirationMessage = "HideExpirationMessage"
    case hideCertificateNumber = "HideCertificateNumber"
    case hideHelp = "HideHelp"
    case hideGetSoftware = "HideGetSoftware"
    case hideLastUser = "HideLastUser"
    case hideLockScreen = "HideLockScreen"
    case hideRenew = "HideRenew"
    case hidePrefs = "HidePrefs"
    case hideSignIn = "HideSignIn"
    case hideTickets = "HideTickets"
    case hideQuit = "HideQuit"
    case hideSignOut = "HideSignOut"
    case homeAppendDomain = "HomeAppendDomain"
    case iconOff = "IconOff"
    case iconOffDark = "IconOffDark"
    case iconOn = "IconOn"
    case iconOnDark = "IconOnDark"
    case kerberosRealm = "KerberosRealm"
    case keychainItems = "KeychainItems"
    case keychainItemsInternet = "KeychainItemsInternet"
    case keychainItemsCreateSerial = "KeychainItemsCreateSerial"
    case keychainItemsDebug = "KeychainItemsDebug"
    case keychainMinderWindowTitle = "KeychainMinderWindowTitle"
    case keychainMinderWindowMessage = "KeychainMinderWindowMessage"
    case keychainMinderShowReset = "KeychainMinderShowReset"
    case keychainPasswordMatch = "KeychainPasswordMatch"
    case lastCertificateExpiration = "LastCertificateExpiration"
    case lightsOutIKnowWhatImDoing = "LightsOutIKnowWhatImDoing"
    case loginComamnd = "LoginComamnd"
    case loginItem = "LoginItem"
    case ldapAnonymous = "LDAPAnonymous"
    case lDAPSchema = "LDAPSchema"
    case lDAPServerList = "LDAPServerList"
    case lDAPServerListDeny = "LDAPServerListDeny"
    case lDAPoverSSL = "LDAPOverSSL"
    case lDAPOnly = "LDAPOnly"
    case lDAPType = "LDAPType"
    case localPasswordSync = "LocalPasswordSync"
    case localPasswordSyncDontSyncLocalUsers = "LocalPasswordSyncDontSyncLocalUsers"
    case localPasswordSyncDontSyncNetworkUsers = "LocalPasswordSyncDontSyncNetworkUsers"
    case localPasswordSyncOnMatchOnly = "LocalPasswordSyncOnMatchOnly"
    case lockedKeychainCheck = "LockedKeychainCheck"
    case lastUser = "LastUser"
    case lastPasswordWarning = "LastPasswordWarning"
    case lastPasswordExpireDate = "LastPasswordExpireDate"
    case loginLogo = "LoginLogo"
    case menuAbout = "MenuAbout"
    case menuAccounts = "MenuAccounts"
    case menuActions = "MenuActions"
    case menuChangePassword = "MenuChangePassword"
    case menuHomeDirectory = "MenuHomeDirectory"
    case menuGetCertificate = "MenuGetCertificate"
    case menuGetHelp = "MenuGetHelp"
    case menuGetSoftware = "MenuGetSoftware"
    case menuFileServers = "MenuFileServers"
    case menuPasswordExpires = "MenuPasswordExpires"
    case menuPreferences = "MenuPreferences"
    case menuRenewTickets = "MenuRenewTickets"
    case menuSignIn = "MenuSignIn"
    case menuSignOut = "MenuSignOut"
    case menuTickets = "MenuTickets"
    case menuUserName = "MenuUserName"
    case menuWelcome = "MenuWelcome"
    case menuQuit = "MenuQuit"
    case menuIconColor = "MenuIconColor"
    case menuIconColorDark = "MenuIconColorDark"
    case messageLocalSync = "MessageLocalSync"
    case messageNotConnected = "MessageNotConnected"
    case messageUPCAlert = "MessageUPCAlert"
    case messagePasswordChangePolicy = "MessagePasswordChangePolicy"
    case mountSharesWithFinder = "MountSharesWithFinder"
    case passwordExpirationDays = "PasswordExpirationDays"
    case passwordExpireAlertTime = "PasswordExpireAlertTime"
    case passwordExpireCustomAlert = "PasswordExpireCustomAlert"
    case passwordExpireCustomWarnTime = "PasswordExpireCustomWarnTime"
    case passwordExpireCustomAlertTime = "PasswordExpireCustomAlertTime"
    case passwordPolicy = "PasswordPolicy"
    case persistExpiration = "PersistExpiration"
    case profileDone = "ProfileDone"
    case profileWait = "ProfileWait"
    case recursiveGroupLookup = "RecursiveGroupLookup"
    case renewTickets = "RenewTickets"
    case showHome = "ShowHome"
    case secondsToRenew = "SecondsToRenew"
    case selfServicePath = "SelfServicePath"
    case shareReset = "ShareReset"        // clean listing of shares between runs
    case signInCommand = "SignInCommand"
    case signInWindowAlert = "SignInWindowAlert"
    case signInWindowAlertTime = "SignInWindowAlertTime"
    case signInWindowOnLaunch = "SignInWindowOnLaunch"
    case signInWindowOnLaunchExclusions = "SignInWindowOnLaunchExclusions"
    case signedIn = "SignedIn"
    case signOutCommand = "SignOutCommand"
    case singleUserMode = "SingleUserMode"
    case siteIgnore = "SiteIgnore"
    case siteForce = "SiteForce"
    case slowMount = "SlowMount"
    case slowMountDelay = "SlowMountDelay"
    case stateChangeAction = "StateChangeAction"
    case switchKerberosUser = "SwitchKerberosUser"
    case template = "Template"
    case titleSignIn = "TitleSignIn"
    case uPCAlert = "UPCAlert"
    case uPCAlertAction = "UPCAlertAction"
    case userCN = "UserCN"
    case userGroups = "UserGroups"
    case userPrincipal = "UserPrincipal"
    case userHome = "UserHome"
    case userPasswordExpireDate = "UserPasswordExpireDate"
    case userCommandTask1 = "UserCommandTask1"
    case userCommandName1 = "UserCommandName1"
    case userCommandHotKey1 = "UserCommandHotKey1"
    case userPasswordSetDate = "UserPasswordSetDate"
    case useKeychain = "UseKeychain"
    case useKeychainPrompt = "UseKeychainPrompt"
    case userAging = "UserAging"
    case userAttributes = "UserAttributes"
    case userEmail = "UserEmail"
    case userFirstName = "UserFirstName"
    case userFullName = "UserFullName"
    case userLastName = "UserLastName"
    case userLastChecked = "UserLastChecked"
    case userShortName = "UserShortName"
    case userSwitch = "UserSwitch"
    case userUPN = "UserUPN"
    case verbose = "Verbose"
    case wifiNetworks = "WifiNetworks"
    case windowSignIn = "WindowSignIn"
    case x509CA = "X509CA"
    case x509Name = "X509Name"
    
    func printAllPrefs() {
        let defaults = UserDefaults.standard
        for key in PrefKeys.allCases {
            let pref = defaults.object(forKey: key.rawValue) as AnyObject
            
            switch String(describing: type(of: pref)) {
            case "__NSCFBoolean" :
                print("\t" + key.rawValue + ": " + String(describing: ( defaults.bool(forKey: key.rawValue))))
            case "__NSCFArray" :
                print("\t" + key.rawValue + ": " + ( String(describing: (defaults.array(forKey: key.rawValue)))))
            case "__NSTaggedDate":
                if let object = pref as? Date {
                    print("\t" + key.rawValue + ": " + object.description(with: Locale.current))
                } else {
                    print("\t" + key.rawValue + ": Unknown")
                }
            case "__NSCFDictionary":
                let description = String(describing: defaults.dictionary(forKey: key.rawValue))
                print("\t" + key.rawValue + ": " + description)
            case "__NSCFData" :
                print("\t" + key.rawValue + ": " + (defaults.data(forKey: key.rawValue)?.base64EncodedString() ?? "Unknown"))
            default :
                print("\t" + key.rawValue + ": " + ( defaults.object(forKey: key.rawValue) as? String ?? "Unset"))
            }
            if defaults.objectIsForced(forKey: key.rawValue) {
                print("\t\tForced")
            }
        }
    }
}
