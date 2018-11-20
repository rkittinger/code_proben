//
//  SubscriptionsManager.m
//
//  Created by Randy Kittinger on 29.12.11.
//  Copyright (c) 2011. All rights reserved.
//

#import "SubscriptionsManager.h"
#import "XMLReader.h"
#import "NSData+Base64.h"
#import "mein_Klub_PEAppDelegate.h"
#import "PushNotificationManager.h"

#if BUILD_LIVE_VERSION == 1
#define BASE_LIVE_URL   @"https://p4s-live.wefind.de/iphone-push/v2/"

#else
#define BASE_LIVE_URL   @"http://p4s-test01.neofonie.de/iphone-push/v2/"

#endif

#define kCustomerID     @"meinKlub.de"
#define kDeviceTest @"MeinKlubTest"

@implementation SubscriptionsManager 
@synthesize contentsOfCurrentProperty, requestName;
@dynamic udidMigratedToP4SDeviceIdentifier;
@synthesize migrateUdidToP4SDeviceIdentifierErrorMessage;


- (void)initializeUserForSubWithUDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier {
    Globals *g = [Globals sharedGlobals];

    if (!g.userID) {

        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@subscription/createInitialSubscription?udId=%@&customerId=%@&deviceId=%@", BASE_LIVE_URL, udid, kCustomerID, p4sIdentifier]];

        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        
        [request setDelegate:self];
        [request setUserInfo:[NSDictionary dictionaryWithObject:@"initRequest" forKey:@"name"]];
        [request setDidFinishSelector:@selector(requestDone:)];
        [request setDidFailSelector:@selector(requestWentWrong:)];
        [request startAsynchronous];
    }
    else {
        NSLog(@"listing products");
        [self getProductsWithUserID:g.userID UDID:g.udid P4SDeviceIdentifier:g.P4SDeviceId];
    }
}

- (void)migrateUserId:(NSString*)userID fromUDID:(NSString*)udid toP4SDeviceIdentifier:(NSString*)p4sIdentifier {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@subscription/migrateId?userId=%@&customerId=%@&udId=%@&deviceId=%@", BASE_LIVE_URL, userID, kCustomerID, udid, p4sIdentifier]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"migrateIdRequest" forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    [request startAsynchronous];
}

- (void)migrateUserIdIfNeeded:(NSString*)userID fromUDID:(NSString*)udid toP4SDeviceIdentifier:(NSString*)p4sIdentifier;
{
    if (self.udidMigratedToP4SDeviceIdentifier)
        return [self getProductsWithUserID:userID UDID:udid P4SDeviceIdentifier:p4sIdentifier];
    
    [self migrateUserId:userID fromUDID:udid toP4SDeviceIdentifier:p4sIdentifier];
}

- (void)deregisterDeviceWithUserID:(NSString*)userid UDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@registration/deregisterDevice?userId=%@&customerId=%@&udId=%@&deviceId=%@", BASE_LIVE_URL, userid, kCustomerID, udid, p4sIdentifier]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"deviceDeregisterRequest" forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    
    [request startAsynchronous];
}

- (void)registerDeviceWithUserID:(NSString*)userid UDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier {
    if (aboCode)
        [aboCode release]; aboCode = nil;
    
    aboCode = [userid retain];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@registration/registerDevice?userId=%@&customerId=%@&udId=%@&deviceId=%@", BASE_LIVE_URL, userid, kCustomerID, udid, p4sIdentifier]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"deviceRequest" forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    
    [request startAsynchronous];
}

- (void)getProductsWithUserID:(NSString*)userid UDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@subscription/isEligible?userId=%@&customerId=%@&udId=%@&deviceId=%@", BASE_LIVE_URL, userid, kCustomerID, udid, p4sIdentifier]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"productRequest" forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    
    [request startAsynchronous];
}

- (void)getProductsWithUserIDExtended:(NSString*)userid UDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@subscription/isEligibleExtended?device=%@&userId=%@&customerId=%@&udId=%@&deviceId=%@", BASE_LIVE_URL, kDeviceTest, userid, kCustomerID, udid, p4sIdentifier]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"productRequest" forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    
    [request startAsynchronous];
}

- (void)createSubscriptionWithUserID:(NSString*)userid andReceipt:(NSData*)receipt forPackage:(NSString*)package {

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@subscription/create?userId=%@&receipt=%@", BASE_LIVE_URL, userid, [receipt base64UrlEncodedStringWithoutLinebreaks]]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];

    NSString *requestStr = @"";
    if ([package isEqualToString:@"radio"])
        requestStr = @"createRequest";
    else if ([package isEqualToString:@"expert"])
        requestStr = @"createExpertRequest";

    [request setUserInfo:[NSDictionary dictionaryWithObject:requestStr forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    
    [request startAsynchronous];
}

- (void)redeemVoucherWithUserID:(NSString*)userid UDID:(NSString*)udid P4SDeviceIdentifier:(NSString*)p4sIdentifier voucher:(NSString*)voucher {
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@promoCode/redeem?userId=%@&customerId=%@&udId=%@&deviceId=%@&code=%@", BASE_LIVE_URL, userid, kCustomerID, udid, p4sIdentifier, voucher]];

    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setDelegate:self];
    [request setUserInfo:[NSDictionary dictionaryWithObject:@"voucherRequest" forKey:@"name"]];
    [request setDidFinishSelector:@selector(requestDone:)];
    [request setDidFailSelector:@selector(requestWentWrong:)];
    
    [request startAsynchronous];
}   

- (void)requestWentWrong:(ASIHTTPRequest *)request {
    Globals *g = [Globals sharedGlobals];

    if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"createRequest"]) {

        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        g.liveRadioPackagePurchased = NO;
        
        [prefs setBool:NO forKey:@"liveradio_purchased"];
        [prefs synchronize];
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc postNotificationName:@"CreateSubscriptionFailed" object:self userInfo:nil];
    } else if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"createExpertRequest"]) {

        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        g.premiumPackagePurchased = NO;
        
        [prefs setBool:NO forKey:@"premium_purchased"];
        [prefs synchronize];
        
        NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
        [dnc postNotificationName:@"CreateSubscriptionForExpertPackageFailed" object:self userInfo:nil];
    }
}

#pragma mark - ASIHTTPRequest Delegate Methods

- (void)requestDone:(ASIHTTPRequest *)request {
    Globals *g = [Globals sharedGlobals];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *response = [request responseString];
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    NSError *parseError = nil;
    
    if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"initRequest"]) {
        NSError *error;
        
        NSDictionary *results = [[XMLReader dictionaryForXMLString:response error:&error] valueForKey:@"result"];

        if ([[results valueForKey:@"status"] isEqualToString:@"ok"]) {

            g.userID = [results valueForKey:@"userId"];

            [prefs setObject:g.userID forKey:@"UserID"];
            [prefs synchronize];
            
            [self migrateUserIdIfNeeded:g.userID fromUDID:g.udid toP4SDeviceIdentifier:g.P4SDeviceId];

            [self getProductsWithUserID:g.userID UDID:g.udid P4SDeviceIdentifier:g.P4SDeviceId];
        } else {
            NSLog(@"ERROR INITIALIZING USER ON SERVER");
        }
    } else if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"migrateIdRequest"]) {
        [self parseXMLFromData:data forRequest:@"migrateIdRequest" parseError:&parseError];
    } else if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"deviceRequest"]) {
        [self parseXMLFromData:data forRequest:@"deviceRequest" parseError:&parseError];
    } else if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"deviceDeregisterRequest"]) {
        [self parseXMLFromData:data forRequest:@"deviceDeregisterRequest" parseError:&parseError];
    } else if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"productRequest"]) {
        [self parseXMLFromData:data forRequest:@"productRequest" parseError:&parseError];
    } else if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"createRequest"]) {
        NSError *error;
        NSDictionary *results = [[XMLReader dictionaryForXMLString:response error:&error] valueForKey:@"result"];
        if ([[results valueForKey:@"status"] isEqualToString:@"ok"]) {

            NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
            if (g.purchasedFromLiveRadioView)
                [dnc postNotificationName:@"FinishPurchaseForLiveRadio" object:self userInfo:nil];
            else
                [dnc postNotificationName:@"FinishPurchaseForIAPView" object:self userInfo:nil];
        } else {
            NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
            [dnc postNotificationName:@"CreateSubscriptionFailed" object:self userInfo:nil];
        }
    } else if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"createExpertRequest"]) {
        NSError *error;
        NSDictionary *results = [[XMLReader dictionaryForXMLString:response error:&error] valueForKey:@"result"];

        if ([[results valueForKey:@"status"] isEqualToString:@"ok"]) {

            NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
            if (g.expertPackagePurchasedFromExpertDetailView)
                [dnc postNotificationName:@"FinishPurchaseForExpertPackageDetail" object:self userInfo:nil];
            else
                [dnc postNotificationName:@"FinishPurchaseForExpertPackage" object:self userInfo:nil];
        } else {
            NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
            [dnc postNotificationName:@"CreateSubscriptionForExpertPackageFailed" object:self userInfo:nil];
        }
    } else if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"createFreePremiumRequest"]) {
        NSError *error;
        NSDictionary *results = [[XMLReader dictionaryForXMLString:response error:&error] valueForKey:@"result"];

        if ([[results valueForKey:@"status"] isEqualToString:@"ok"]) {

            UIAlertView *errorView = [[[UIAlertView alloc] 
                                       initWithTitle: nil 
                                       message: @"Sie haben 30 Tage, das Expertenpaket zu testen." 
                                       delegate: self 
                                       cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
            
            [errorView show];
            
            [prefs setBool:YES forKey:@"TestPremiumPurchased"];
            [prefs setBool:YES forKey:@"TestPremiumAlreadyPurchased"];
            g.testPremiumPackagePurchased = YES;
            g.alreadyPurchasedFreePremium = YES;
            [prefs synchronize];
        } else {
            [prefs setBool:NO forKey:@"TestPremiumAlreadyPurchased"];
            [prefs setBool:NO forKey:@"TestPremiumPurchased"];
            g.alreadyPurchasedFreePremium = NO;
            g.testPremiumPackagePurchased = NO;
            [prefs synchronize];

            UIAlertView *errorView = [[[UIAlertView alloc] 
                                       initWithTitle: nil 
                                       message: @"Es gibt Probleme mit dem Server, bitte versuchen Sie es später noch einmal." 
                                       delegate: self 
                                       cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Wiederholen", nil] autorelease];
            errorView.tag = 1;
            [errorView show];
        }
    } else if ([[request.userInfo valueForKey:@"name"] isEqualToString:@"voucherRequest"]) {

        NSError *error;
        NSDictionary *results = [[XMLReader dictionaryForXMLString:response error:&error] valueForKey:@"result"];
        
        if ([[results valueForKey:@"status"] isEqualToString:@"ok"]) {

            Globals *g = [Globals sharedGlobals];
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setBool:YES forKey:@"liveradio_purchased"];
            [prefs synchronize];
            
            g.purchasedFromLiveRadioView = NO;
            g.purchasedFromIAPView = NO;
            g.premiumPackageTrackString = @"prem/radio";
            g.liveRadioPackagePurchased = YES;
            
            NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
            [dnc postNotificationName:@"VoucherEntrySucceeded" object:self userInfo:nil];
        }
        else {
            UIAlertView *errorView = [[[UIAlertView alloc] 
                                       initWithTitle: @"Gutschein-Code ungültig" 
                                       message: @"Bitte stellen Sie sicher, dass Sie den Gutschein-Code korrekt eingegeben haben." 
                                       delegate: self 
                                       cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
            [errorView show];
        }
    }
}

- (BOOL)parseXMLFromData:(NSData*)xmlData forRequest:(NSString*)request parseError:(NSError **)error {
    BOOL result = YES;
    
    self.requestName = nil;
    requestName = [request retain];
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xmlData];
    [parser setDelegate:self];
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

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    self.migrateUdidToP4SDeviceIdentifierErrorMessage = nil;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    Globals *g = [Globals sharedGlobals];

    if (qName) {
        elementName = qName;
    }
    
    if ([elementName isEqualToString:@"result"]) {
        if ([requestName isEqualToString:@"deviceDeregisterRequest"]) {
            if (![[attributeDict objectForKey:@"status"] isEqualToString:@"ok"]) {
                
                //send error
                return;
            }
            else {
                NSLog(@"deregister successful");
            }
        } else if ([requestName isEqualToString:@"deviceRequest"]) {
            if (![[attributeDict objectForKey:@"status"] isEqualToString:@"ok"]) {
                
                //Abo-Code nicht akzeptiert
                //send error
                UIAlertView *alertView = [[UIAlertView alloc] 
                                          initWithTitle: nil 
                                          message: @"Abo-Code nicht akzeptiert" 
                                          delegate: self 
                                          cancelButtonTitle: @"OK" otherButtonTitles: nil];
                [alertView show];
                [alertView release];
                
                return;
            } else { //SUCCESS

                [prefs setBool:YES forKey:@"SubscriptionInitSuccessful"];
                
                if (![g.userID isEqualToString:aboCode]) {
                    [self deregisterDeviceWithUserID:g.userID UDID:g.udid P4SDeviceIdentifier:g.P4SDeviceId];

                    NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
                    [dnc postNotificationName:@"AboCodeEntrySucceeded" object:self userInfo:nil];
                    g.userID = aboCode;
                    [prefs setObject:g.userID forKey:@"UserID"];

                    [self getProductsWithUserID:g.userID UDID:g.udid P4SDeviceIdentifier:g.P4SDeviceId];
                }
                
                [prefs synchronize];
            }
        } else if ([requestName isEqualToString:@"initRequest"]) {
            if (![[attributeDict objectForKey:@"status"] isEqualToString:@"ok"]) {

                return;
            } else { //SUCCESS

                g.userID = [attributeDict valueForKey:@"userId"];
                
                [prefs setObject:g.userID forKey:@"UserID"];
                [prefs synchronize];

                [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge |UIRemoteNotificationTypeSound)];

                [self getProductsWithUserID:g.userID UDID:g.udid P4SDeviceIdentifier:g.P4SDeviceId];
            }
        } else if ([requestName isEqualToString:@"migrateIdRequest"]) {

            NSString* status = [[attributeDict objectForKey:@"status"] lowercaseString];
            if ([status isEqualToString:@"ok"]) {
                [self getProductsWithUserID:g.userID UDID:g.udid P4SDeviceIdentifier:g.P4SDeviceId];
                return [self setUdidMigratedToP4SDeviceIdentifier:YES];
            }
            
            self.migrateUdidToP4SDeviceIdentifierErrorMessage = [NSMutableString string];
            self.contentsOfCurrentProperty = [NSMutableString string];
        } else if ([requestName isEqualToString:@"createRequest"]) {

            if (![[attributeDict objectForKey:@"status"] isEqualToString:@"ok"]) {

                Globals *g = [Globals sharedGlobals];
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                
                
                [prefs setBool:NO forKey:@"liveradio_purchased"];
                [prefs synchronize];
                
                NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
                [dnc postNotificationName:@"CreateSubscriptionFailed" object:self userInfo:nil];
                g.liveRadioPackagePurchased = NO;

                return;
            }
            else {
                NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
                if (g.purchasedFromLiveRadioView)
                    [dnc postNotificationName:@"FinishPurchaseForLiveRadio" object:self userInfo:nil];
                else
                    [dnc postNotificationName:@"FinishPurchaseForIAPView" object:self userInfo:nil]; 
            }
        } else if ([requestName isEqualToString:@"createExpertRequest"]) {

            if (![[attributeDict objectForKey:@"status"] isEqualToString:@"ok"]) {

                Globals *g = [Globals sharedGlobals];
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];

                [prefs setBool:NO forKey:@"premium_purchased"];
                [prefs synchronize];
                
                NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
                [dnc postNotificationName:@"CreateSubscriptionForExpertPackageFailed" object:self userInfo:nil];
                g.premiumPackagePurchased = NO;

                return;
            } else {
                NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];

                if (g.expertPackagePurchasedFromExpertDetailView)
                    [dnc postNotificationName:@"FinishPurchaseForExpertPackageDetail" object:self userInfo:nil];
                else
                    [dnc postNotificationName:@"FinishPurchaseForExpertPackage" object:self userInfo:nil]; 
            }
            
        } else if ([requestName isEqualToString:@"createFreePremiumRequest"]) {

            if (![[attributeDict objectForKey:@"status"] isEqualToString:@"ok"]) {

                Globals *g = [Globals sharedGlobals];
                NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
                
                
                [prefs setBool:NO forKey:@"TestPremiumPurchased"];
                [prefs synchronize];

                g.testPremiumPackagePurchased = NO;

                UIAlertView *errorView = [[[UIAlertView alloc] 
                                           initWithTitle: nil 
                                           message: @"Es gibt Probleme mit dem Server, bitte versuchen Sie es später noch einmal." 
                                           delegate: self 
                                           cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Wiederholen", nil] autorelease];
                errorView.tag = 1;
                [errorView show];

                return;
            } else {
                UIAlertView *errorView = [[[UIAlertView alloc] 
                                           initWithTitle: nil 
                                           message: @"Sie haben 30 Tage das Expertenpaket zu testen." 
                                           delegate: self 
                                           cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
                
                [errorView show];
                
                [prefs setBool:YES forKey:@"TestPremiumPurchased"];
                [prefs setBool:YES forKey:@"TestPremiumAlreadyPurchased"];
                g.testPremiumPackagePurchased = YES;
                g.alreadyPurchasedFreePremium = YES;
                [prefs synchronize];
            }
        }
    } else if([elementName isEqualToString:@"subscription"]) {
        if ([[attributeDict objectForKey:@"valid"] isEqualToString:@"true"])
            productIsValid = YES;
        else
            productIsValid = NO;
    } else if([elementName isEqualToString:@"productId"] && productIsValid)
        self.contentsOfCurrentProperty = [NSMutableString string];
    else if([elementName isEqualToString:@"productId"] && !productIsValid)
        self.contentsOfCurrentProperty = [NSMutableString string];
    else if([elementName isEqualToString:@"expires"] && !productIsValid)
        self.contentsOfCurrentProperty = [NSMutableString string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    Globals *g = [Globals sharedGlobals];
    
    if (qName) {
        elementName = qName;
    }
    
    if([elementName isEqualToString:@"subscription"])
        productIsValid = NO;
    else if([elementName isEqualToString:@"productId"] && productIsValid) {
        if ([self.contentsOfCurrentProperty isEqualToString:g.radioProductId]) {

            g.liveRadioPackagePurchased = YES;
            
            [prefs setBool:YES forKey:@"liveradio_purchased"];
            [prefs synchronize];
            
            g.premiumPackageTrackString = @"prem/radio";
        } else if ([self.contentsOfCurrentProperty isEqualToString:g.expertProductId]) {

            g.premiumPackagePurchased = YES;
            
            [prefs setBool:YES forKey:@"premium_purchased"];
            [prefs synchronize];
        } else if ([self.contentsOfCurrentProperty isEqualToString:g.premiumFreeProductId]) {

            g.testPremiumPackagePurchased = YES;
            
            [prefs setBool:YES forKey:@"TestPremiumPurchased"];
            [prefs synchronize];
        }
    }
    else if ([elementName isEqualToString:@"expires"] && !productIsValid) {
        expiredTime = [self.contentsOfCurrentProperty doubleValue];
        g.expiredTime = expiredTime;
    } else if ([elementName isEqualToString:@"productId"] && !productIsValid) {
        if ([self.contentsOfCurrentProperty isEqualToString:g.radioProductId]) {

            g.liveRadioPackagePurchased = NO;
            
            [prefs setBool:NO forKey:@"liveradio_purchased"];
            [prefs removeObjectForKey:@"radioPackageReceipt"];
            [prefs synchronize];
            
            g.premiumPackageTrackString = @"free";
        } else if ([self.contentsOfCurrentProperty isEqualToString:g.expertProductId]) {

            g.premiumPackagePurchased = NO;
            
            [prefs setBool:NO forKey:@"premium_purchased"];
            [prefs removeObjectForKey:@"expertPackageReceipt"];
            [prefs synchronize];
        } else if ([self.contentsOfCurrentProperty isEqualToString:g.premiumFreeProductId]) {

            g.expiredTime = expiredTime;
            
            g.testPremiumPackagePurchased = NO;
            
            [prefs setBool:NO forKey:@"TestPremiumPurchased"];
            [prefs synchronize];
        }
    } else if ([elementName isEqualToString:@"message"]) {
        if ([self.migrateUdidToP4SDeviceIdentifierErrorMessage length] == 0) {
            // This is no error message due to requesting a udid migration, so bail out here.
            // We aren't interested in any other error message at the moment.
            return;
        }
        
        [self.migrateUdidToP4SDeviceIdentifierErrorMessage appendString:self.contentsOfCurrentProperty];
        if ([[self.migrateUdidToP4SDeviceIdentifierErrorMessage lowercaseString] rangeOfString:@"udid migration failed"].location != NSNotFound) {
            // Migration failed, due to already migrated.
            self.udidMigratedToP4SDeviceIdentifier = YES;

            [self getProductsWithUserID:g.userID UDID:g.udid P4SDeviceIdentifier:g.P4SDeviceId];
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
    [aboCode release];
    [contentsOfCurrentProperty release];
    [requestName release];
    self.migrateUdidToP4SDeviceIdentifierErrorMessage = nil;
    [super dealloc];
}

#pragma mark Properties

- (BOOL) udidMigratedToP4SDeviceIdentifier; {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"udidMigratedToP4SDeviceIdentifier"];
}

- (void) setUdidMigratedToP4SDeviceIdentifier:(BOOL)udidMigratedToP4SDeviceIdentifier; {
    [[NSUserDefaults standardUserDefaults] setBool:udidMigratedToP4SDeviceIdentifier forKey:@"udidMigratedToP4SDeviceIdentifier"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

//for free product!!!
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {

            NSLog(@"trying again");
        }
    }
}

@end
