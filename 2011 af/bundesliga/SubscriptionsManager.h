//
//  SubscriptionsManager.h
//
//  Created by Randy Kittinger on 29.12.11.
//  Copyright (c) 2011. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

@interface SubscriptionsManager : NSObject <ASIHTTPRequestDelegate, NSXMLParserDelegate> {

    BOOL productIsValid;
    NSString *aboCode;
    
    NSTimeInterval expiredTime;
}

@property (nonatomic, retain) NSMutableString *contentsOfCurrentProperty;
@property (nonatomic, retain) NSString *requestName;
@property (nonatomic, assign) BOOL udidMigratedToP4SDeviceIdentifier;

- (BOOL)parseXMLFromData:(NSData*)xmlData forRequest:(NSString*)request parseError:(NSError **)error;

- (void)initializeUserForSubWithUDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier;
- (void)migrateUserId:(NSString*)userID fromUDID:(NSString*)udid toP4SDeviceIdentifier:(NSString*)p4sIdentifier;
- (void)migrateUserIdIfNeeded:(NSString*)userID fromUDID:(NSString*)udid toP4SDeviceIdentifier:(NSString*)p4sIdentifier;
- (void)registerDeviceWithUserID:(NSString*)userid UDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier;
- (void)deregisterDeviceWithUserID:(NSString*)userid UDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier;
- (void)getProductsWithUserID:(NSString*)userid UDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier;

- (void)redeemVoucherWithUserID:(NSString*)userid UDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier voucher:(NSString*)voucher;

- (void)createSubscriptionWithUserID:(NSString*)userid andReceipt:(NSData*)receipt forPackage:(NSString*)package;

- (void)getProductsWithUserIDExtended:(NSString*)userid UDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier;

@end

@interface SubscriptionsManager ()

@property (nonatomic, retain) NSMutableString* migrateUdidToP4SDeviceIdentifierErrorMessage;

@end
