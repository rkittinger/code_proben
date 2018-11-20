//
//  PushNotificationManager.h
//
//  Created by Randy Kittinger on 24.11.11.
//  Copyright (c) 2011. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASIHTTPRequest.h"

@interface PushNotificationManager : NSObject <ASIHTTPRequestDelegate, NSXMLParserDelegate> {
    BOOL retryingListRequest;
    BOOL forMatchNotifications;
} 

@property (nonatomic, retain) NSString *requestName;
@property (nonatomic, retain) NSOperationQueue *queue;
@property (nonatomic, retain) NSMutableString *contentsOfCurrentProperty;

- (BOOL)parseXMLFromData:(NSData*)xmlData forRequest:(NSString*)request parseError:(NSError **)error;

- (void)registerDeviceForPushNotificationsWithUserID:(NSString*)userid andUDID:(NSString*)udid andP4SDeviceIdentifier:(NSString*)p4sDeviceId andDeviceToken:(NSString*)token forMatch:(BOOL)flag;
- (void)listRegisteredAlertsWithUserID:(NSString*)userid;
- (void)resetBadgeWithUserID:(NSString*)userid;
- (void)disablePushNotificationsWithFeedID:(NSString*)feedID;
- (void)enablePushNotificationsWithFeedID:(NSString*)feedID;
- (void)deleteOldNotificationSettings;

@end
