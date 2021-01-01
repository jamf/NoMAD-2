//
//  TCSecurity.h
//  SMIME Reader
//
//  
//  Copyright 2012-2017 Twocanoes Software Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Security/Security.h>

@interface TCSecurity : NSObject {

}

+(NSData *)wrappedSignature:(NSData *)inSignature;
+(NSData *)wrappedPublicKeyFromModulus:(NSData *)inModulus andExponent:(NSData *)inExponent;
+ (NSData *)sha512:(NSData *)data ;
+ (NSData *)signBytes:(NSData *)plainText withPrivateKey:(SecKeyRef)privateKey;
//+(NSData *)convertPEMtoDER:(NSString *)inPEM;
+(void)addKeyToKeychain:(SecKeyRef)inKey withLabel:(NSString *)inLabel;
+(NSData *)wrappedPublicKeyFromSecKeyRef:(SecKeyRef)inPublicKey;
+(NSData *)generatePublicKeyFromPrivateKey:(SecKeyRef)privateKey;
+(SecKeyRef)generatePrivateKeyWithIdentifer:(NSString *)inIdentifer;
+(int)installCertificate:(NSData *)inCert keychain:(NSString *)keychainPath error:(NSError **)returnErr;

@end
