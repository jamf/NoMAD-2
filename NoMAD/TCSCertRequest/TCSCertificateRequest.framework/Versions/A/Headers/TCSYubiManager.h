//
//  TCSYubiManager.h
//  TCSCertificateRequest
//
//  Created by Tim Perfitt on 2/24/18.
//  Copyright © 2018 Twocanoes Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCSYubiManager : NSObject

@property (nonatomic, strong) NSData *publicKey;

+ (id)sharedManager;

-(BOOL)authenticateWithManagementKey:(NSString *)inKey;
- (NSData *)signBytes:(NSData *)inData withYubiKeySlot:(NSString *)slot ;
-(BOOL)installCertificate:(NSData *)inCert intoSlot:(NSString *)inSlot;
-(NSData *)generateKeyInSlot:(NSString *)slot;
@end
