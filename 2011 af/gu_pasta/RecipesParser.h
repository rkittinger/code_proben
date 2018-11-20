//
//  RecipesParser.h
//  GU Pasta
//
//  Created by Randy Kittinger on 08.08.11.
//  Copyright 2011 appsfactory GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CoreDataHelper.h"
#import "Rezept.h"
#import "Zutat.h"
#import "Zutaten.h"
#import "Zutaten2.h"
#import "Kochanleitung.h"
#import "Kochanleitung2.h"
#import "Textabsatz.h"
#import "Farbe.h"
#import "App.h"

@interface RecipesParser : NSObject <NSXMLParserDelegate>{
	NSMutableString *contentsOfCurrentProperty;
	NSManagedObjectContext *managedObjectContext;

    App *currentApp;
	Rezept *currentRecipe;
    Zutat *currentIngredient;
	Zutaten *currentZutaten1;
    Zutaten2 *currentZutaten2;
    Kochanleitung *currentKochanleitung1;
    Kochanleitung2 *currentKochanleitung2;
    Textabsatz *currentTextabsatz;
    Farbe *currentFarbe;

    NSManagedObject *currentZutaten;
    NSManagedObject *currentKochanleitung;
    NSUInteger recipeNum;
    BOOL ignoreIngredientGroup;
    BOOL ignoreShortText; //Kurztext unter Kochanleitung
    BOOL inTipEntity;

    BOOL ignoreValue;
}
@property (retain, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) NSMutableString *contentsOfCurrentProperty;
-(id) initWithContext: (NSManagedObjectContext *) managedObjContext;
-(BOOL)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error;
-(void) emptyDataContext;

@end
