//
//  MKGameDaysClubViewController.h
//
//  Created by Randy Kittinger on 08.11.11.
//  Copyright (c) 2011. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlideMenuView.h"

@class MKPartyViewController;
@class MKConferenceTicker;

@interface MKLiveGamesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
    NSUInteger confButtonTag;
  
    NSTimer *refreshTimer;

    IBOutlet UITableView *tv;
    IBOutlet UITableViewCell *_cell;
    NSMutableArray *rows;
    NSString *tempLeague;

    BOOL refreshing;

    BOOL shouldShowTablesInPartyView;
}
@property (nonatomic, retain) MKConferenceTicker *conferenceTicker;
@property (nonatomic, retain) MKPartyViewController *partyViewController;
@property (nonatomic, retain) IBOutlet UILabel *noGamesLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, readonly) NSURL *liveURL;
@property (assign) BOOL forBLGames;
@property (nonatomic, retain) NSTimer *refreshTimer;
@property (nonatomic, retain) NSMutableArray *confButtonArray;
@property (nonatomic, retain) UITableView *tv;
@property (nonatomic, retain) NSMutableArray *rows;
@property (nonatomic, retain) UITableViewCell *_cell;

- (NSString*)getDateString;
- (void)getLiveGamesWithDate:(NSString*)dateStr;
- (NSString*)getFullDateFromString:(NSString*)dateString;
- (void)refreshTables;

- (NSString*)reformatDateFromString:(NSString*)dateString forPartyOverview:(BOOL)flag;
- (void)startTracker;
- (IBAction)showConferenceTicker:(id)sender;
@end
