//
//  MKGameDaysClubViewController.m
//
//  Created by Randy Kittinger on 08.11.11.
//  Copyright (c) 2011. All rights reserved.
//

#import "MKLiveGamesViewController.h"
#import "GameDaysResultsCellView.h"
#import "GameDaysResultsNormalCellView.h"
#import "GameDaysResultsLiveCellView.h"
#import "mein_Klub_PEAppDelegate.h"
#import "MKPartyViewController.h"
#import "Leagues.h"
#import "SeasonID.h"
#import "MKConferenceTicker.h"

@implementation MKLiveGamesViewController
@synthesize tv, spinner;
@synthesize _cell, rows, confButtonArray;
@synthesize noGamesLabel, partyViewController, forBLGames;
@synthesize refreshTimer, liveURL, conferenceTicker;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    confButtonTag = 0;

    spinner.hidden = NO;
    [spinner startAnimating];

    [self getLiveGamesWithDate:[self getDateString]];
}

- (IBAction)showConferenceTicker:(id)sender {
    Globals *g = [Globals sharedGlobals];
    UIButton *btn = (UIButton*)sender;
    NSUInteger btnButtonIndex = btn.tag;
    NSUInteger confButtonCoID = [[[confButtonArray objectAtIndex:btnButtonIndex] valueForKey:@"coid"] intValue];
  
    NSCalendar* cal = [NSCalendar currentCalendar];

    NSDateComponents* comps = [cal components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:[NSDate date]];

    NSDate* dayForTicker = [cal dateFromComponents:comps];

    if(!self.conferenceTicker) {
        MKConferenceTicker *controller = [[MKConferenceTicker alloc] initWithNibName:@"MKConferenceTicker" bundle:nil];

        self.conferenceTicker = controller;
        
        [controller release];
    }

    self.conferenceTicker.liveGame = YES;

    self.conferenceTicker.shouldShowTables = [[[confButtonArray objectAtIndex:btnButtonIndex] valueForKey:@"standing"] boolValue];;//shouldShowTablesInPartyView
    self.conferenceTicker.cameFromTables = NO;
   
    self.conferenceTicker.season = [[confButtonArray objectAtIndex:btnButtonIndex] valueForKey:@"seasonid"];
    self.conferenceTicker.roundID = [[[confButtonArray objectAtIndex:btnButtonIndex] valueForKey:@"roundid"] intValue];
    
    self.conferenceTicker.today = dayForTicker;
    self.conferenceTicker.cameFromLiveGames = YES;
    
    if (confButtonCoID == 12 || confButtonCoID == 3) {
          NSUInteger matchDay = [[[confButtonArray objectAtIndex:btnButtonIndex] valueForKey:@"matchday"] intValue];
        self.conferenceTicker.cameFromTournament = NO;
        self.conferenceTicker.week = matchDay;
    } else if (confButtonCoID == 19 || confButtonCoID == 33 || confButtonCoID == 132 || confButtonCoID == 36) {
        self.conferenceTicker.cameFromTournament = YES;
        
        NSString *roundName =   [[confButtonArray objectAtIndex:btnButtonIndex] valueForKey:@"roundname"];
        g.chosenGroup = roundName;

        if ([roundName isEqualToString:@"2. Runde"] ||
            [roundName isEqualToString:@"Achtelfinale"] ||
            [roundName isEqualToString:@"Viertelfinale"] || 
            [roundName isEqualToString:@"Halbfinale"] ||
            [roundName isEqualToString:@"Finale"]) {
            self.conferenceTicker.clelKORound = YES;
            
            NSUInteger matchDay = [[[confButtonArray objectAtIndex:btnButtonIndex] valueForKey:@"matchday"] intValue];
            self.conferenceTicker.week = matchDay;
        } else {
            self.conferenceTicker.forGroupGame = YES;
            self.conferenceTicker.clelKORound = NO;
            NSUInteger groupMatchDay = [[[confButtonArray objectAtIndex:btnButtonIndex] valueForKey:@"groupmatchday"] intValue];
            self.conferenceTicker.groupMatchday = groupMatchDay;
        }
    } else {
        self.conferenceTicker.cameFromTournament = NO;
        NSUInteger matchDay = [[[confButtonArray objectAtIndex:btnButtonIndex] valueForKey:@"matchday"] intValue];
        self.conferenceTicker.week = matchDay;
    }

    self.conferenceTicker.forAllLiveGames = NO;
    self.conferenceTicker.chosenCoID = confButtonCoID;
    [self.navigationController pushViewController:self.conferenceTicker animated:YES];
}

- (NSString*)getDateString {

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    NSDate *today = [NSDate date];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    
    NSString *newDate = [dateFormat stringFromDate:today];  
    [dateFormat release];

    return newDate;
}

- (void)viewDidLoad {

    [super viewDidLoad];
    self.navigationItem.backBarButtonItem = [[[UIBarButtonItem alloc] 
                                              initWithTitle:@"Zurück" 
                                              style:UIBarButtonItemStyleDone 
                                              target:nil 
                                              action:nil] autorelease];
}

-(void) refreshTables {
    refreshing = YES;
    [self getLiveGamesWithDate:[self getDateString]];
}

-(void)startTracker {
    Globals *g = [Globals sharedGlobals];

    NSMutableDictionary* zusatzinfos = [NSMutableDictionary dictionary]; 
    [zusatzinfos setObject:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"cs1"]; 
    [zusatzinfos setObject:g.systemVersion forKey:@"cs2"];
    [zusatzinfos setObject:g.premiumPackageTrackString forKey:@"cs3"]; 

    [zusatzinfos setObject:@"mehr" forKey:@"cg1"];
    NSString *parm = @"";

    if (forBLGames)
        parm = @"liveticker";
    else
        parm = @"livescores";
    
    [zusatzinfos setObject:parm forKey:@"cg2"];
    
    [zusatzinfos setObject:@"" forKey:@"cg3"]; 

    [UIAppDelegate.tracking trackContent:[NSString stringWithFormat:@"mehr/%@", parm] additionalParameters:zusatzinfos];
}

- (void)getLiveGamesWithDate:(NSString*)dateStr {

    if (liveURL) {
        [liveURL release]; liveURL = nil;}
        liveURL = [[NSURL URLWithString:[NSString stringWithFormat:@"%@da%@", GAMESOFDAY_URL, dateStr]] retain];
   
    [[AFCache sharedInstance] cachedObjectForURL:liveURL delegate:self];
}

#pragma mark Notifications from NetWorkHandling

- (void) connectionDidFail:(AFCacheableItem *)cacheableItem 
{
    UIAlertView *errorView = [[[UIAlertView alloc] 
                              initWithTitle: nil 
                              message: @"Datenverbindung konnte nicht hergestellt werden" 
                              delegate: self 
                              cancelButtonTitle: @"OK" otherButtonTitles: nil] autorelease];
    [errorView show];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationHideHoverView object:nil];
}

- (void) connectionDidFinish:(AFCacheableItem *)cacheableItem {
    
    NSError *reason = nil;

    if (!refreshing)
        [self startTracker];    
    NSArray *testArray = [NSDictionary dictionaryWithJSONData:cacheableItem.data error:&reason];
 
    NSString *leagueString = @"";
    NSString *currentSeasonID = @"";
   
    [rows release]; rows = nil;
    rows = [[NSMutableArray alloc] init];
    
    [confButtonArray release]; confButtonArray = nil;
    confButtonArray = [[NSMutableArray alloc] init]; 
    
    if ([testArray count] > 0) {
        BOOL standing;

        NSUInteger numLiveGames = 0;
        int confButtonIndex = 0;
        BOOL shouldShowNoGameLabel = YES;

        for (NSDictionary *mainDict in testArray) {
            
            NSUInteger coID = [[mainDict valueForKey:@"competition_id"] intValue];

            if (forBLGames) {
                if (coID != 14 && coID != 91 && coID != 97 && coID != 111 && coID != 71 && coID != 13 && coID != 37 && coID != 49 && coID != 123 && coID != 93 && coID != 115 && coID != 116 && coID != 95 && coID != 20 && coID != 571 && coID != 1172) {

                    leagueString = [mainDict valueForKey:@"competition_name"];
                    currentSeasonID = [mainDict valueForKey:@"season_id"];

                    NSMutableArray *array = [[mainDict valueForKey:@"matches"] mutableCopy];
                    
                    NSMutableDictionary *rowDict = [[[NSMutableDictionary alloc] init] autorelease];
                    NSMutableDictionary *liveRowDict = [[[NSMutableDictionary alloc] init] autorelease];
                    NSMutableDictionary *confButtonDict = [[[NSMutableDictionary alloc] init] autorelease];
               
                    [rowDict setValue:leagueString forKey:@"league"];
                    [rowDict setValue:[NSNumber numberWithInt:coID] forKey:@"coid"];
                    [rowDict setValue:currentSeasonID forKey:@"seasonid"];

                    NSMutableArray *liveGamesArray = [NSMutableArray array];
                    
                    NSString *roundName = @"";
                    NSUInteger matchDay = 0;
                    NSUInteger roundID = 0;
                    NSUInteger groupMatchDay = 0;

                    for (NSDictionary *liveGamesDict in array) {
                        if (![[liveGamesDict objectForKey:@"current_period"] isEqualToString:@"game-end"] &&
                            ![[liveGamesDict objectForKey:@"current_period"] isEqualToString:@""]&&
                            ![[liveGamesDict objectForKey:@"incident"] isEqualToString:@"abgebr."] &&
                            [[liveGamesDict objectForKey:@"live_status"] isEqualToString:@"full"]) {

                            numLiveGames++;
                            [liveGamesArray addObject:liveGamesDict];

                            standing = [[liveGamesDict valueForKey:@"standing"] boolValue];

                            roundID = [[liveGamesDict valueForKey:@"round_id"] intValue];

                            if ((coID == 19 || coID == 33 || coID == 132 || coID == 36) && groupMatchDay == 0) {
                                groupMatchDay = [[liveGamesDict valueForKey:@"group_matchday"] intValue];

                                roundName = [liveGamesDict valueForKey:@"round_name"];
                            }
                            else if (matchDay == 0) {
                                matchDay = [[liveGamesDict valueForKey:@"matchday"] intValue];
                                roundName = [liveGamesDict valueForKey:@"round_name"];
                            }
                        }
                    }

                    if (groupMatchDay > 0)
                        [confButtonDict setValue:[NSNumber numberWithInt:groupMatchDay] forKey:@"groupmatchday"];
                    
                    if (matchDay > 0)
                        [confButtonDict setValue:[NSNumber numberWithInt:matchDay] forKey:@"matchday"];
                    
                    [confButtonDict setValue:[NSNumber numberWithInt:roundID] forKey:@"roundid"];
                    [confButtonDict setValue:roundName forKey:@"roundname"];
                     [confButtonDict setValue:currentSeasonID forKey:@"seasonid"];
                    [confButtonDict setValue:[NSNumber numberWithBool:standing] forKey:@"standing"];
                    [confButtonDict setValue:[NSNumber numberWithInt:coID] forKey:@"coid"];
                    [confButtonDict setValue:[NSNumber numberWithInt:confButtonIndex] forKey:@"index"];
                    [confButtonArray addObject:confButtonDict];

                    if (numLiveGames > 0) {
                        
                        [liveRowDict setValue:leagueString forKey:@"league"];
                        [liveRowDict setValue:[NSNumber numberWithInt:coID] forKey:@"coid"];
                        [liveRowDict setValue:[NSNumber numberWithInt:confButtonIndex] forKey:@"index"];

                        confButtonIndex++;

                        [liveRowDict setValue:currentSeasonID forKey:@"seasonid"];
                        
                        for (NSDictionary *dictTemp in liveGamesArray) {
                            [array removeObject:dictTemp];
                        }

                        NSMutableArray *editArray = [array mutableCopy];

                        for (NSDictionary *dict in array) {
                            if (![[dict objectForKey:@"live_status"] isEqualToString:@"full"]) {
                                [editArray removeObject:dict];
                            }
                        }

                        [rowDict setValue:editArray forKey:@"rowValues"];
                        [rowDict setValue:[NSNumber numberWithInt:0] forKey:@"numLiveGames"];
                        [rows addObject:rowDict];
                        [editArray release];

                        [liveRowDict setValue:liveGamesArray forKey:@"rowValues"];
                        [liveRowDict setValue:[NSNumber numberWithInt:numLiveGames] forKey:@"numLiveGames"];
                        [rows addObject:liveRowDict];
                        shouldShowNoGameLabel = NO;
                    }
                    else {

                        NSMutableArray *editArray = [array mutableCopy];

                        for (NSDictionary *dict in array) {
                            
                            
                            if (![[dict objectForKey:@"live_status"] isEqualToString:@"full"]) {
                                NSLog(@"removing dict: %@", dict);
                                [editArray removeObject:dict];
                            }
                        }

                        if (editArray.count > 0) {

                            [rowDict setValue:editArray forKey:@"rowValues"];
                            [rowDict setValue:[NSNumber numberWithInt:0] forKey:@"numLiveGames"];

                            [rows addObject:rowDict];
                        }

                        [editArray release];

                        if ([rows count] > 0) {
                            shouldShowNoGameLabel = NO;
                        } else {
                            shouldShowNoGameLabel = YES;
                        }
                    }

                    numLiveGames = 0;

                    if ([rows count] > 0)
                        noGamesLabel.hidden = YES;
                    else if (shouldShowNoGameLabel) {
                        noGamesLabel.hidden = NO;
                    
                        noGamesLabel.text = @"Heute gibt es leider keine Spiele im Liveticker.";
                       
                        [self.view bringSubviewToFront:noGamesLabel];
                    }
                } else if (shouldShowNoGameLabel) {
                    noGamesLabel.hidden = NO;
                    
                    noGamesLabel.text = @"Heute gibt es leider keine Spiele im Liveticker.";
                    
                    [self.view bringSubviewToFront:noGamesLabel];
                }
            } else {

                if (coID != 12 && coID != 3 && coID != 19 && coID != 33 && coID != 132 && coID != 571 && coID != 1172) { //571 = Freundschaft

                    if (coID == 20)
                        leagueString = @"Championship England";
                    else if (coID == 13)
                        leagueString = @"Österreich";
                    else if (coID == 14)
                        leagueString = @"BL Frauen";
                    else
                        leagueString = [mainDict valueForKey:@"competition_name"];

                    currentSeasonID = [mainDict valueForKey:@"season_id"];

                    NSMutableArray *array = [[mainDict valueForKey:@"matches"] mutableCopy];
                    
                    NSMutableDictionary *rowDict = [[[NSMutableDictionary alloc] init] autorelease];
                    NSMutableDictionary *liveRowDict = [[[NSMutableDictionary alloc] init] autorelease];

                    [rowDict setValue:leagueString forKey:@"league"];
                    [rowDict setValue:[NSNumber numberWithInt:coID] forKey:@"coid"];
                    [rowDict setValue:currentSeasonID forKey:@"seasonid"];

                    NSMutableArray *liveGamesArray = [NSMutableArray array];

                    for (NSDictionary *liveGamesDict in array) {
                        BOOL hasLiveStatusFull = [[liveGamesDict objectForKey:@"live_status"] isEqualToString:@"full"];
                        BOOL hasLiveStatusNone = [[liveGamesDict objectForKey:@"live_status"] isEqualToString:@"none"];

                        if (hasLiveStatusFull)
                            continue;

                        if (hasLiveStatusNone)
                            continue;

                        if (![[liveGamesDict objectForKey:@"current_period"] isEqualToString:@"game-end"] &&
                            ![[liveGamesDict objectForKey:@"current_period"] isEqualToString:@""]&&
                            ![[liveGamesDict objectForKey:@"incident"] isEqualToString:@"abgebr."]) {
                            
                            numLiveGames++;
                            [liveGamesArray addObject:liveGamesDict];
                        }

                    }

                    if (numLiveGames > 0) {
                        [liveRowDict setValue:leagueString forKey:@"league"];
                        [liveRowDict setValue:[NSNumber numberWithInt:coID] forKey:@"coid"];
                        [liveRowDict setValue:currentSeasonID forKey:@"seasonid"];
                        
                        for (NSDictionary *dictTemp in liveGamesArray) {
                            [array removeObject:dictTemp];
                        }

                        NSMutableArray *editArray = [array mutableCopy];

                        for (NSDictionary *dict in array) {
                            if ([[dict objectForKey:@"live_status"] isEqualToString:@"none"]) [editArray removeObject:dict];
                            if ([[dict objectForKey:@"live_status"] isEqualToString:@"full"]) [editArray removeObject:dict];
                        }

                        [rowDict setValue:editArray forKey:@"rowValues"];
                        [rowDict setValue:[NSNumber numberWithInt:0] forKey:@"numLiveGames"];
                        [rows addObject:rowDict];
                        
                        [liveRowDict setValue:liveGamesArray forKey:@"rowValues"];
                        [liveRowDict setValue:[NSNumber numberWithInt:numLiveGames] forKey:@"numLiveGames"];
                        [rows addObject:liveRowDict];
                        shouldShowNoGameLabel = NO;
                    } else {
                        NSMutableArray *editArray = [array mutableCopy];
                        for (NSDictionary *dict in array) {
                            if ([[dict objectForKey:@"live_status"] isEqualToString:@"none"]) [editArray removeObject:dict];
                            if ([[dict objectForKey:@"live_status"] isEqualToString:@"full"]) [editArray removeObject:dict];
                        }
                        
                        if (editArray.count > 0) {
                            [rowDict setValue:editArray forKey:@"rowValues"];
                            [rowDict setValue:[NSNumber numberWithInt:0] forKey:@"numLiveGames"];
                            [rows addObject:rowDict];
                        }

                        [editArray release];
                        
                        if ([rows count] > 0)
                            shouldShowNoGameLabel = NO;
                        else {
                            shouldShowNoGameLabel = YES;
                        }
                    }

                    numLiveGames = 0;
                    
                    if ([rows count] > 0) {
                        noGamesLabel.hidden = YES;
                    } else if (shouldShowNoGameLabel) {
                        
                        noGamesLabel.hidden = NO;

                        noGamesLabel.text = @"Heute gibt es leider keine Livescores.";
                      
                        [self.view bringSubviewToFront:noGamesLabel];
                    }
                }

                if (shouldShowNoGameLabel) {
                    noGamesLabel.hidden = NO;
                    
                    noGamesLabel.text = @"Heute gibt es leider keine Livescores.";
                    
                    [self.view bringSubviewToFront:noGamesLabel];
                }
            }
        }
    } else {
        noGamesLabel.hidden = NO;
        
        if (forBLGames)
            noGamesLabel.text = @"Heute gibt es leider keine Spiele im Liveticker.";
        else {
            noGamesLabel.text = @"Heute gibt es leider keine Livescores.";
        }
        [self.view bringSubviewToFront:noGamesLabel];
    }
    
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    spinner.hidden = YES;
    [spinner stopAnimating];

    if ([self.refreshTimer isValid]) {
        [self.refreshTimer invalidate];
    }
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refreshTables) userInfo:nil repeats:NO];
    refreshing = NO;

    [tv reloadData];
}

- (NSString*)getFullDateFromString:(NSString*)dateString {

    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    [dateFormat setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]
                           autorelease]];
    NSDate *date = [dateFormat dateFromString:dateString];  
    
    // Convert date object to desired output format
    [dateFormat setDateFormat:@"EEEE, dd. MMMM yyyy"];
    
    NSString *newDate = [dateFormat stringFromDate:date];  
    [dateFormat release];

    return newDate;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = [rows objectAtIndex:indexPath.section];
    NSUInteger coID = [[dict valueForKey:@"coid"] intValue];

    NSArray *array = [[dict objectForKey:@"rowValues"] objectAtIndex:indexPath.row];
    NSUInteger roundID = [[array valueForKey:@"round_id"] intValue];

    if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {

    if (!self.partyViewController) {
        MKPartyViewController *controller = [[MKPartyViewController alloc] initWithNibName:@"MKPartyViewController" bundle:nil];
        self.partyViewController = controller;
        [controller release];
    }
    
    refreshing = YES;

    self.partyViewController.matchID = [array valueForKey:@"id"];
        
    self.partyViewController.roundID = roundID;

    self.partyViewController.fullDateString = [self getFullDateFromString:[array valueForKey:@"date"]];

    if (![[array valueForKey:@"second_half"] isEqualToString:@":"]) {

        self.partyViewController.inSecondHalf = YES;
    } else if (![[array valueForKey:@"first_half"] isEqualToString:@":"]) {
    
        self.partyViewController.inSecondHalf = NO;
    } else {
        self.partyViewController.inSecondHalf = NO;
    }

    if (![[array valueForKey:@"current_period"] isEqualToString:@"game-end"] &&
        ![[array valueForKey:@"current_period"] isEqualToString:@""] &&
        ![[array valueForKey:@"incident"] isEqualToString:@"abgebr."]) {
        self.partyViewController.liveGame = YES;
        self.partyViewController.futureGame = NO;

        if ([[array valueForKey:@"live_status"] isEqualToString:@"full"])
            self.partyViewController.showLiveTickerButton = YES;
        else
            self.partyViewController.showLiveTickerButton = NO;
    } else {
        self.partyViewController.liveGame = NO;

        if ([[array valueForKey:@"finished"] isEqualToString:@"no"]) {

            if ([[array valueForKey:@"incident"] isEqualToString:@"abgebr."])
                self.partyViewController.futureGame = NO;
            else
                self.partyViewController.futureGame = YES;
                          
                if ([[array valueForKey:@"time"] isEqualToString:@"unknown"]) {
                    self.partyViewController.dateTimeString = [NSString stringWithFormat:@"%@", [self reformatDateFromString:[array valueForKey:@"date"] forPartyOverview:YES]];
                } else {
                    self.partyViewController.dateTimeString = [NSString stringWithFormat:@"%@ %@ Uhr", [self reformatDateFromString:[array valueForKey:@"date"] forPartyOverview:YES], [array valueForKey:@"time"]];
                }
            } else {
                if ([[array valueForKey:@"live_status"] isEqualToString:@"full"])
                    self.partyViewController.showLiveTickerButton = YES;
                else
                    self.partyViewController.showLiveTickerButton = NO;
                    self.partyViewController.futureGame = NO;
             }
        }
    self.partyViewController.cameFromTables = NO;
    self.partyViewController.cameFromClubOverview = YES;

    if (coID == 12 || coID == 3) {
        self.partyViewController.cameFromTournament = NO;
        self.partyViewController.matchDay = [[array valueForKey:@"matchday"] intValue];
    }
    else if (coID == 19 || coID == 33 || coID == 132 || coID == 36) {
        self.partyViewController.cameFromTournament = YES;
        self.partyViewController.groupMatchday = [[array valueForKey:@"group_matchday"] intValue];
    }
    else {
        self.partyViewController.cameFromTournament = NO;
        self.partyViewController.matchDay = [[array valueForKey:@"matchday"] intValue];
    }

    self.partyViewController.chosenCoID = coID;

    self.partyViewController.seasonID = [dict valueForKey:@"seasonid"];

    if ([[array valueForKey:@"home_microname"] length] > 0 && [[array valueForKey:@"away_microname"] length] > 0)
        self.partyViewController.title = [NSString stringWithFormat:@"%@ - %@", [array valueForKey:@"home_microname"], [array valueForKey:@"away_microname"]];
    else
        self.partyViewController.title = @"";
    
    [self.navigationController pushViewController:self.partyViewController animated:YES];

    }
}

- (NSString*)reformatDateFromString:(NSString*)dateString forPartyOverview:(BOOL)flag {

    // Convert string to date object
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [dateFormat dateFromString:dateString];  
    
    // Convert date object to desired output format
    
    if (!flag)
        [dateFormat setDateFormat:@"dd.MM.yyyy"];
    else
        [dateFormat setDateFormat:@"dd.MM.yy"];
    NSString *newDate = [dateFormat stringFromDate:date];  
    [dateFormat release];

    return newDate;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    
    return [rows count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
  
    return [[[rows objectAtIndex:section] objectForKey:@"rowValues"] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        
    Globals *g = [Globals sharedGlobals];
    
    NSDictionary *dict = [rows objectAtIndex:indexPath.section];

    NSArray *array = [[dict objectForKey:@"rowValues"] objectAtIndex:indexPath.row];

    NSUInteger numLiveGames = [[dict valueForKey:@"numLiveGames"] intValue];

    if (numLiveGames >0) {
        NSUInteger confButtonIndex = [[dict valueForKey:@"index"] intValue];
        if (indexPath.row == 0) {
            static NSString *CellIdentifier = @"GameDaysResultsLiveCell";
            GameDaysResultsLiveCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"GameDaysResultsLiveCellView" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
            }

            if ([[dict objectForKey:@"rowValues"] count] > 1) {

                if ([[array valueForKey:@"home_id"] isEqualToString:g.teamID] || [[array valueForKey:@"away_id"] isEqualToString:g.teamID])
                    cell.bgImage.image = [UIImage imageNamed:@"liveTop_HI.png"];
                else
                    cell.bgImage.image = [UIImage imageNamed:@"liveTop_LO.png"];
                
                cell.bgImage.hidden = NO;
                cell.bgImageSingle.hidden = YES;
            }
            else {
                if ([[array valueForKey:@"home_id"] isEqualToString:g.teamID] || [[array valueForKey:@"away_id"] isEqualToString:g.teamID])
                    cell.bgImageSingle.image = [UIImage imageNamed:@"live_HI.png"];
                else
                    cell.bgImageSingle.image = [UIImage imageNamed:@"live_LO.png"];
                
                cell.bgImageSingle.hidden = NO;
                cell.bgImage.hidden = YES;
            }
           
            if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                cell.arrow.hidden = NO;
            }
            else
                cell.arrow.hidden = YES;

            if (![[array valueForKey:@"current_period"] isEqualToString:@"game-end"] &&
                ![[array valueForKey:@"current_period"] isEqualToString:@""] &&
                ![[array valueForKey:@"incident"] isEqualToString:@"abgebr."])
                cell.currentMinuteLabel.text = [NSString stringWithFormat:@"%@. Minute", [array valueForKey:@"current_minute"]];
            else {
                if (![[array valueForKey:@"incident"] isEqualToString:@""]) {
                    cell.currentMinuteLabel.text = [array valueForKey:@"incident"];
                    cell.currentMinuteLabel.hidden = NO;
                }
                else
                    cell.currentMinuteLabel.hidden = YES;
            }

            cell.awayTeamLabel.text = [array valueForKey:@"away_name"];
            cell.homeTeamLabel.text = [array valueForKey:@"home_name"];

            [cell.homeTeamImageView setLogoForTeamID:[array valueForKey:@"home_id"] forType:3];
            [cell.awayTeamImageView setLogoForTeamID:[array valueForKey:@"away_id"] forType:3];

            // LIVE STATUS: FULL
            if (![[array valueForKey:@"current_period"] isEqualToString:@"game-end"] &&
                ![[array valueForKey:@"current_period"] isEqualToString:@""] &&
                ![[array valueForKey:@"incident"] isEqualToString:@"abgebr."]) {

                if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                    if ([[array valueForKey:@"live"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"live"];
                } else {
                    if ([[array valueForKey:@"full"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"full"];
                }
            } else {
                if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                    if ([[array valueForKey:@"live"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else if ([[array valueForKey:@"full"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"live"];
                } else {
                    if ([[array valueForKey:@"full"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"full"];
                }
            }
            
            return cell;
        } else if (indexPath.row == [[dict objectForKey:@"rowValues"] count]-1) {
            static NSString *CellIdentifier = @"LiveGameWithConfButtonCell";
            GameDaysResultsNormalCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"LiveGameWithConfButtonCell" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
            }

            if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                cell.arrow.hidden = NO;
            }
            else
                cell.arrow.hidden = YES;

                if ([[array valueForKey:@"home_id"] isEqualToString:g.teamID] || [[array valueForKey:@"away_id"] isEqualToString:g.teamID])
                    cell.bgImage.image = [UIImage imageNamed:@"gdBtm_HI.png"];
                else
                    cell.bgImage.image = [UIImage imageNamed:@"gdBtm_LO.png"];

            UIButton *confButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0, 38.0, 310.0, 34.0)];
            [confButton setImage:[UIImage imageNamed:@"btn_conferenceticker_new.png"] forState:UIControlStateNormal];
            [confButton addTarget:self action:@selector(showConferenceTicker:) forControlEvents:UIControlEventTouchUpInside];
            [confButton setTag:confButtonIndex];
            [cell.contentView addSubview:confButton];
            [confButton release];

            cell.scoreLabel.frame = CGRectMake(cell.scoreLabel.frame.origin.x, 1.0, cell.scoreLabel.frame.size.width, cell.scoreLabel.frame.size.height);

            if (![[array valueForKey:@"current_period"] isEqualToString:@"game-end"] &&
                ![[array valueForKey:@"current_period"] isEqualToString:@""] &&
                ![[array valueForKey:@"incident"] isEqualToString:@"abgebr."])
                	cell.currentMinuteLabel.text = [NSString stringWithFormat:@"%@. Minute", [array valueForKey:@"current_minute"]];
            else {
                if (![[array valueForKey:@"incident"] isEqualToString:@""]) {
                    cell.currentMinuteLabel.text = [array valueForKey:@"incident"];
                    cell.currentMinuteLabel.hidden = NO;
                } else
                    cell.currentMinuteLabel.hidden = YES;
            }
            
            cell.awayTeamLabel.text = [array valueForKey:@"away_name"];
            cell.homeTeamLabel.text = [array valueForKey:@"home_name"];
            
            [cell.homeTeamImageView setLogoForTeamID:[array valueForKey:@"home_id"] forType:3];
            [cell.awayTeamImageView setLogoForTeamID:[array valueForKey:@"away_id"] forType:3];

            if (![[array valueForKey:@"current_period"] isEqualToString:@"game-end"] &&
                ![[array valueForKey:@"current_period"] isEqualToString:@""] &&
                ![[array valueForKey:@"incident"] isEqualToString:@"abgebr."]) {

                if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                    if ([[array valueForKey:@"live"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"live"];
                } else {
                    if ([[array valueForKey:@"full"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"full"];
                }
            } else {
                if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                    if ([[array valueForKey:@"live"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else if ([[array valueForKey:@"full"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"live"];
                } else {
                    if ([[array valueForKey:@"full"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"full"];
                }
            }
            
            return cell;
        }
        else {

            static NSString *CellIdentifier = @"GameDaysResultsNormalCell";
            GameDaysResultsNormalCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"GameDaysResultsNormalCellView" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
            }

            if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                cell.arrow.hidden = NO;
            } else
                cell.arrow.hidden = YES;
            
            if (indexPath.row == [[dict objectForKey:@"rowValues"] count]-1) {
                if ([[array valueForKey:@"home_id"] isEqualToString:g.teamID] || [[array valueForKey:@"away_id"] isEqualToString:g.teamID])
                    cell.bgImage.image = [UIImage imageNamed:@"gdBtm_HI.png"];
                else
                    cell.bgImage.image = [UIImage imageNamed:@"gdBtm_LO.png"];
            } else {
                if ([[array valueForKey:@"home_id"] isEqualToString:g.teamID] || [[array valueForKey:@"away_id"] isEqualToString:g.teamID])
                    cell.bgImage.image = [UIImage imageNamed:@"gdMid_HI.png"];
                else
                    cell.bgImage.image = [UIImage imageNamed:@"gdMid_LO.png"]; 
            }
            
            cell.scoreLabel.frame = CGRectMake(cell.scoreLabel.frame.origin.x, 1.0, cell.scoreLabel.frame.size.width, cell.scoreLabel.frame.size.height);

            if (![[array valueForKey:@"current_period"] isEqualToString:@"game-end"] &&
                ![[array valueForKey:@"current_period"] isEqualToString:@""] &&
                ![[array valueForKey:@"incident"] isEqualToString:@"abgebr."])
                	cell.currentMinuteLabel.text = [NSString stringWithFormat:@"%@. Minute", [array valueForKey:@"current_minute"]];
            else {
                if (![[array valueForKey:@"incident"] isEqualToString:@""]) {
                    cell.currentMinuteLabel.text = [array valueForKey:@"incident"];
                    cell.currentMinuteLabel.hidden = NO;
                } else
                    cell.currentMinuteLabel.hidden = YES;
            }
            
            cell.awayTeamLabel.text = [array valueForKey:@"away_name"];
            cell.homeTeamLabel.text = [array valueForKey:@"home_name"];
            
            [cell.homeTeamImageView setLogoForTeamID:[array valueForKey:@"home_id"] forType:3];
            [cell.awayTeamImageView setLogoForTeamID:[array valueForKey:@"away_id"] forType:3];

            if (![[array valueForKey:@"current_period"] isEqualToString:@"game-end"] &&
                ![[array valueForKey:@"current_period"] isEqualToString:@""] &&
                ![[array valueForKey:@"incident"] isEqualToString:@"abgebr."]) {

                if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                    if ([[array valueForKey:@"live"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"live"];
                } else {
                    if ([[array valueForKey:@"full"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"full"];
                }
            } else {
                if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                    if ([[array valueForKey:@"live"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else if ([[array valueForKey:@"full"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"live"];
                } else {
                    if ([[array valueForKey:@"full"] isEqualToString:@":"])
                        cell.scoreLabel.text = @"-:-";
                    else
                        cell.scoreLabel.text = [array valueForKey:@"full"];
                }
            }

            return cell;
        }
        
    } else {
        
        if (indexPath.row == 0) {
            static NSString *CellIdentifier = @"GameDaysResultsCell";
            GameDaysResultsCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

            if (cell == nil) {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"GameDaysResultsCellView" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
            }

            if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                cell.arrow.hidden = NO;
            } else
                cell.arrow.hidden = YES;

            if ([[dict objectForKey:@"rowValues"] count] > 1) {

                if ([[array valueForKey:@"home_id"] isEqualToString:g.teamID] || [[array valueForKey:@"away_id"] isEqualToString:g.teamID])
                    cell.bgImage.image = [UIImage imageNamed:@"gdTop_HI.png"];
                else
                    cell.bgImage.image = [UIImage imageNamed:@"gdTop_LO.png"];
                
                cell.bgImageSingle.hidden = YES;
                cell.bgImage.hidden = NO;
            } else {
                if ([[array valueForKey:@"home_id"] isEqualToString:g.teamID] || [[array valueForKey:@"away_id"] isEqualToString:g.teamID])
                    cell.bgImageSingle.image = [UIImage imageNamed:@"single_HI.png"];
                else
                    cell.bgImageSingle.image = [UIImage imageNamed:@"single_LO.png"];
                
                cell.bgImageSingle.hidden = NO;
                cell.bgImage.hidden = YES;
            }
            
            cell.dateLabel.text = [dict valueForKey:@"league"];

            if (![[array valueForKey:@"incident"] isEqualToString:@""]) {
                
                cell.currentMinuteLabel.text = [array valueForKey:@"incident"];
                cell.currentMinuteLabel.hidden = NO;

            }
            else {
                if ([[array valueForKey:@"time"]isEqualToString:@"unknown"])
                    cell.currentMinuteLabel.text = @"--:-- Uhr";
                else
                    cell.currentMinuteLabel.text = [NSString stringWithFormat:@"%@ Uhr", [array valueForKey:@"time"]];
            }

            cell.awayTeamLabel.text = [array valueForKey:@"away_name"];
            cell.homeTeamLabel.text = [array valueForKey:@"home_name"];

            [cell.homeTeamImageView setLogoForTeamID:[array valueForKey:@"home_id"] forType:3];
            [cell.awayTeamImageView setLogoForTeamID:[array valueForKey:@"away_id"] forType:3];

            if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                if ([[array valueForKey:@"live"] isEqualToString:@":"])
                    cell.scoreLabel.text = @"-:-";
                else if ([[array valueForKey:@"full"] isEqualToString:@":"])
                    cell.scoreLabel.text = @"-:-";
                else
                    cell.scoreLabel.text = [array valueForKey:@"live"];
            } else {
                if ([[array valueForKey:@"full"] isEqualToString:@":"])
                    cell.scoreLabel.text = @"-:-";
                else
                    cell.scoreLabel.text = [array valueForKey:@"full"];
            }
            
            return cell;
        } else {
            
            static NSString *CellIdentifier = @"GameDaysResultsNormalCell";
            GameDaysResultsNormalCellView *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                NSArray *nibArray = [[NSBundle mainBundle] loadNibNamed:@"GameDaysResultsNormalCellView" owner:self options:nil];
                cell = [nibArray objectAtIndex:0];
            }

            if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                cell.arrow.hidden = NO;
            }
            else
                cell.arrow.hidden = YES;

            if (indexPath.row == [[dict objectForKey:@"rowValues"] count]-1) {
                if ([[array valueForKey:@"home_id"] isEqualToString:g.teamID] || [[array valueForKey:@"away_id"] isEqualToString:g.teamID])
                    cell.bgImage.image = [UIImage imageNamed:@"gdBtm_HI.png"];
                else
                    cell.bgImage.image = [UIImage imageNamed:@"gdBtm_LO.png"];
            } else {
                if ([[array valueForKey:@"home_id"] isEqualToString:g.teamID] || [[array valueForKey:@"away_id"] isEqualToString:g.teamID])
                    cell.bgImage.image = [UIImage imageNamed:@"gdMid_HI.png"];
                else
                    cell.bgImage.image = [UIImage imageNamed:@"gdMid_LO.png"];
            }

            cell.awayTeamLabel.text = [array valueForKey:@"away_name"];
            cell.homeTeamLabel.text = [array valueForKey:@"home_name"];

            if (![[array valueForKey:@"incident"] isEqualToString:@""]) {
                
                cell.currentMinuteLabel.text = [array valueForKey:@"incident"];
                cell.currentMinuteLabel.hidden = NO;
            } else {
                if ([[array valueForKey:@"time"]isEqualToString:@"unknown"])
                    cell.currentMinuteLabel.text = @"--:-- Uhr";
                else
                    cell.currentMinuteLabel.text = [NSString stringWithFormat:@"%@ Uhr", [array valueForKey:@"time"]];
            }

            if (cell.scoreLabel.frameY == 1.0)
                cell.scoreLabel.frameY = 5.0;
            
            [cell.homeTeamImageView setLogoForTeamID:[array valueForKey:@"home_id"] forType:3];
            [cell.awayTeamImageView setLogoForTeamID:[array valueForKey:@"away_id"] forType:3];

            if (![[array valueForKey:@"live_status"] isEqualToString:@"none"]) {
                if ([[array valueForKey:@"live"] isEqualToString:@":"])
                    cell.scoreLabel.text = @"-:-";
                else if ([[array valueForKey:@"full"] isEqualToString:@":"])
                    cell.scoreLabel.text = @"-:-";
                else
                    cell.scoreLabel.text = [array valueForKey:@"live"];
            } else {
                if ([[array valueForKey:@"full"] isEqualToString:@":"])
                    cell.scoreLabel.text = @"-:-";
                else
                    cell.scoreLabel.text = [array valueForKey:@"full"];
            }

            return cell;
        }
    }
 }

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = [rows objectAtIndex:indexPath.section];
    NSUInteger numLiveGames = [[dict valueForKey:@"numLiveGames"] intValue];

    if (indexPath.row == 0)
        return 57;
    else if (indexPath.row == [[dict objectForKey:@"rowValues"] count]-1 && numLiveGames > 0)
        return 75;
    else
        return 36;
}

- (void)dealloc {
    
    if (liveURL != nil) {
        [[AFCache sharedInstance] cancelConnectionsForURL:liveURL];
        [[AFCache sharedInstance] removeObjectForURL:liveURL];    
    }
    [liveURL release];

    if ([self.refreshTimer isValid]) {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
    }
    [conferenceTicker release];
    [noGamesLabel release];
    [confButtonArray release];

    [spinner release];

    [partyViewController release];
    [_cell release];
    [rows release];

    [tv release];

    [super dealloc];
}

- (void)viewWillDisappear:(BOOL)animated {

    if ([self.refreshTimer isValid]) {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
    }
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload {
    if ([self.refreshTimer isValid]) {
        [self.refreshTimer invalidate];
        self.refreshTimer = nil;
    }
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
