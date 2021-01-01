//
//  SecurityPrivateAPI.h
//  NoMAD
//
//  Created by Phillip Boushy on 4/26/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

#ifndef SecurityAPI_h
#define SecurityAPI_h

// So we can use SecKeychainChangePassword() in NoMADUser
#import <Security/Security.h>
extern OSStatus SecKeychainItemSetAccessWithPassword(SecKeychainItemRef item, SecAccessRef access, UInt32 passLength, const void* password);
extern OSStatus SecKeychainChangePassword(SecKeychainRef keychainRef, UInt32 oldPasswordLength, const void* oldPassword, UInt32 newPasswordLength, const void* newPassword);
extern OSStatus SecKeychainResetLogin(UInt32 passwordLength, const void* password, Boolean resetSearchList);

#endif /* SecurityAPI_h */
