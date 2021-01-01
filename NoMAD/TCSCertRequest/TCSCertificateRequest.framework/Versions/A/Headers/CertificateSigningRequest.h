//
//  CertificateSigningRequest.h
//  TCSCertificateRequest
//
//  Created by Tim Perfitt on 2/14/18.
//  Copyright © 2018 Twocanoes Software. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CertificateSigningRequest : NSObject
@property (nonatomic, strong) NSData *signatureData;

- (instancetype)initWithPublicKey:(NSData *)inPublicKey commonName:(NSString *)inCommonName;
-(NSData *)messageToSign;
-(NSData *)certificateSigningRequest;
@end
