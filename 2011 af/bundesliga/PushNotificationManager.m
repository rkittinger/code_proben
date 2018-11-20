//
//  PushNotificationManager.m
//
//  Created by Randy Kittinger on 24.11.11.
//  Copyright (c) 2011. All rights reserved.
//

#import "PushNotificationManager.h"
#import "XMLReader.h"
#import "NSData+Base64.h"
#import "mein_Klub_PEAppDelegate.h"


#if BUILD_LIVE_VERSION == 1
#define BASE_LIVE_URL   @"https://p4s-live.wefind.de/iphone-push/v2/"

#else
#define BASE_LIVE_URL   @"http://p4s-test01.neofonie.de/iphone-push/v2/"

#endif

#define kCustomerID     @"meinKlub.de"

@implementation PushNotificationManager 
@synthesize queue, contentsOfCurrentProperty, requestName;

#pragma mark - Request Initialization Methods

- (void)registerDeviceForPushNotificationsWithUserID:(NSString*)userid andUDID:(NSString*)udid andP4SDeviceIdentifier:(NSString*)p4sDeviceId andDeviceToken:(NSString*)token forMatch:(BOOL)flag {
    forMatchNotifications = flag;

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@registration/registerDeviceToken?userId=%@&customerId=%@&udId=%@&deviceId=%@&deviceToken=%@", BASE_LIVE_URL, userid, kCustomerID, udid, p4sDeviceId, token]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"deviceRequest" forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    
    [request startAsynchronous];
}

- (void)listRegisteredAlertsWithUserID:(NSString*)userid {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@newsflash/listAlerts?userId=%@&customerId=%@", BASE_LIVE_URL, userid, kCustomerID]];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];

    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"listRequest" forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    [request startAsynchronous];
}

- (void)enablePushNotificationsWithFeedID:(NSString*)feedID {

    Globals *g = [Globals sharedGlobals];

    if (![self queue]) {
        [self setQueue:[[[NSOperationQueue alloc] init] autorelease]];
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@newsflash/create?userId=%@&feedId=%@&customerId=%@&udId=%@&deviceToken=%@&deviceId=%@", BASE_LIVE_URL, g.userID, feedID, kCustomerID, g.udid, g.deviceToken, g.P4SDeviceId]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"alertRequest" forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    [[self queue] addOperation:request]; //queue is an NSOperationQueue
}

- (void)disablePushNotificationsWithFeedID:(NSString*)feedID {

    Globals *g = [Globals sharedGlobals];

    if (![self queue]) {
        [self setQueue:[[[NSOperationQueue alloc] init] autorelease]];
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@newsflash/delete?userId=%@&customerId=%@&feedId=%@", BASE_LIVE_URL, g.userID, kCustomerID, feedID]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"deleteRequest" forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    [[self queue] addOperation:request]; //queue is an NSOperationQueue
}

- (void)resetBadgeWithUserID:(NSString*)userid {

    Globals *g = [Globals sharedGlobals];

    if (![self queue]) {
        [self setQueue:[[[NSOperationQueue alloc] init] autorelease]];
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@notify/resetApplicationBadge?userId=%@&customerId=%@", BASE_LIVE_URL, g.userID, kCustomerID]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"resetBadgeRequest" forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    [[self queue] addOperation:request];
}

#pragma mark - ASIHTTPRequest Delegate Methods

- (void)requestDone:(ASIHTTPRequest *)request
{
    Globals *g = [Globals sharedGlobals];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *response = [request responseString];

    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSError *parseError = nil;

    NSError *error;
    
	NSDictionary *results = [[XMLReader dictionaryForXMLString:response error:&error] valueForKey:@"result"];

    if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"deviceRequest"]) {

        if ([[results valueForKey:@"status"] isEqualToString:@"ok"]) {

            [prefs setBool:YES forKey:@"PushNotificationsInitSuccessful"];
            [prefs synchronize];
            
            //LIST REGISTERED ALERTS
            [self listRegisteredAlertsWithUserID:g.userID];
        } else {
            NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
            
            if (!forMatchNotifications)
                [dnc postNotificationName:@"DeviceRegisterFailed" object:self userInfo:nil];
            else
                [dnc postNotificationName:@"DeviceRegisterFailedForMatch" object:self userInfo:nil];
        }
    }
    else if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"listRequest"]) {
        [self parseXMLFromData:data forRequest:@"listRequest" parseError:&parseError];
    }
}

- (void)requestWentWrong:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    
    if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"deviceRequest"]) {
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc postNotificationName:@"DeviceRegisterFailed" object:self userInfo:nil];
    }
}


- (BOOL)parseXMLFromData:(NSData*)xmlData forRequest:(NSString*)request parseError:(NSError **)error 
{
	BOOL result = YES;
    
    self.requestName = nil;
    requestName = [request retain];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
    // NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:URL];
    // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    [parser setDelegate:self];
    // Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
    
    [parser parse];
    
    NSError *parseError = [parser parserError];
    if (parseError && error) {
        *error = parseError;
		result = NO;
    }
    
    [parser release];
    
    return result;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{

    if (qName) {
        elementName = qName;
    }

    if ([requestName isEqualToString:@"listRequest"]) {
        if ([elementName isEqualToString:@"alert"]) {

            if (!retryingListRequest)
                [self disablePushNotificationsWithFeedID:[attributeDict objectForKey:@"name"]];
        }
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     

    if (qName) {
        elementName = qName;
    }
    
    if ([requestName isEqualToString:@"listRequest"]) {
        
        if ([elementName isEqualToString:@"alerts"]) {
            
            if (self.queue.operationCount == 0) {
                retryingListRequest = NO;
                [UIAppDelegate checkNotificationSettingsForMatch:forMatchNotifications];
            } else {

                retryingListRequest = YES;

                [UIAppDelegate checkNotificationSettingsForMatch:forMatchNotifications];
            }
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (self.contentsOfCurrentProperty) {
        [self.contentsOfCurrentProperty appendString:string];
    }
}

- (void)dealloc {
    [requestName release];
    [contentsOfCurrentProperty release];
    [queue release];

    [super dealloc];
}

@end
