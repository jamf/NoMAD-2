//
//  TCSADCertificateRequest.h
//  TCSCertificateRequest
//
//  Created by Tim Perfitt on 2/27/18.
//  Copyright © 2018 Twocanoes Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TCSADCertificateRequest : NSObject
@property (nonatomic, readonly, strong) NSData *certificate;
- (instancetype)initWithServerName:(NSString *)serverName certificateAuthorityName:(NSString *)certificateAuthorityName certificateTemplate:(NSString *)certificateTemplate verbose:(BOOL)isVerbose error:(NSError **)error;

-(NSData *)submitRequestToActiveDirectoryWithCSR:(NSData *)inCSR error:(NSError **)error;
@end
