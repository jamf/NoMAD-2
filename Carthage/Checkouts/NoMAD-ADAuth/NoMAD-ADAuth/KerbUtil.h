//
//  Header.h
//  NoMAD
//
//  Created by Joel Rennich on 4/26/16.
//  Copyright © 2016 Orchard & Grove Inc. All rights reserved.
//

#ifndef Header_h
#define Header_h

#import <Foundation/Foundation.h>
#import <GSS/GSS.h>
#import <Cocoa/Cocoa.h>
#import <Security/Security.h>
#import <DirectoryService/DirectoryService.h>
#import <OpenDirectory/OpenDirectory.h>

extern OSStatus SecKeychainItemSetAccessWithPassword(SecKeychainItemRef item, SecAccessRef access, UInt32 passLength, const void* password);

@interface KerbUtil : NSObject
@property (nonatomic, assign, readonly) BOOL						finished;   // observable

- (NSString *)getKerbCredentials:(NSString *)password :(NSString *)userPrincipal;
- (NSString *)changeKerbPassword:(NSString *)oldPassword :(NSString *)newPassword :(NSString *)userPrincipal;
- (int)checkPassword:(NSString *)myPassword;
- (int)changeKeychainPassword:(NSString *)oldPassword :(NSString *)newPassword;
- (OSStatus)resetKeychain:(NSString *)password;

@end

#endif /* Header_h */
