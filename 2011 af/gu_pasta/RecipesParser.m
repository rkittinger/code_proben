//
//  RecipesParser.m
//  GU Pasta
//
//  Created by Randy Kittinger on 08.08.11.
//  Copyright 2011 appsfactory GmbH. All rights reserved.
//

#import "RecipesParser.h"


@implementation RecipesParser
@synthesize managedObjectContext;
@synthesize contentsOfCurrentProperty;

-(id) initWithContext: (NSManagedObjectContext *) managedObjContext
{
	self = [super init];
	[self setManagedObjectContext:managedObjContext];
	ignoreIngredientGroup = NO;
    ignoreShortText = NO;
    inTipEntity = NO;
    //appVariablesSet = NO;
    ignoreValue = YES;
	return self;
}


- (BOOL)parseXMLFileAtURL:(NSURL *)URL parseError:(NSError **)error
{
	BOOL result = YES;
    recipeNum = 0;

    // insert colors into 'Farbe' entity
    // ideal would be a value "FarbeID" in XML
    for (int i=1; i <= 54; i++) {
    
        currentFarbe= (Farbe *)[NSEntityDescription insertNewObjectForEntityForName:@"Farbe" inManagedObjectContext:managedObjectContext];
		[currentFarbe setFarbeID:[NSNumber numberWithInt:i]];
        
        if (i==1) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:247]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:198]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:0]];
        }
        else if (i==2) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:246]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:166]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:0]];
        }
        else if (i==3) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:238]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:127]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:0]];
        }
        else if (i==4) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:231]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:81]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:19]];
        }
        else if (i==5) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:236]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:115]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:96]];
        }
        else if (i==6) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:230]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:68]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:72]];
        }
        else if (i==7) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:227]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:27]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:42]];
        }
        else if (i==8) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:185]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:17]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:39]];
        }
        else if (i==9) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:170]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:67]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:76]];
        }
        else if (i==10) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:140]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:50]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:67]];
        }
        else if (i==11) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:210]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:106]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:69]];
        }
        else if (i==12) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:186]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:54]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:26]];
        }
        else if (i==13) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:165]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:79]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:45]];
        }
        else if (i==14) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:178]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:124]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:59]];
        }
        else if (i==15) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:210]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:152]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:69]];
        }
        else if (i==16) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:126]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:69]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:24]];
        }
        else if (i==17) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:126]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:92]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:72]];
        }
        else if (i==18) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:112]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:72]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:68]];
        }
        else if (i==19) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:95]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:71]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:57]];
        }
        else if (i==20) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:110]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:97]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:74]];
        }
        else if (i==21) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:222]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:181]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:0]];
        }
        else if (i==22) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:198]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:154]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:0]];
        }
        else if (i==23) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:152]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:140]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:59]];
        }
        else if (i==24) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:166]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:171]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:17]];
        }
        else if (i==25) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:186]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:206]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:50]];
        }
        else if (i==26) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:139]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:175]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:69]];
        }
        else if (i==27) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:101]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:176]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:60]];
        }
        else if (i==28) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:39]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:148]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:57]];
        }
        else if (i==29) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:153]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:192]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:128]];
        }
        else if (i==30) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:125]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:162]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:95]];
        }
        else if (i==31) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:66]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:121]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:62]];
        }
        else if (i==32) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:111]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:174]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:139]];
        }
        else if (i==33) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:45]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:150]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:104]];
        }
        else if (i==34) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:0]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:103]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:79]];
        }
        else if (i==35) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:85]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:176]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:156]];
        }
        else if (i==36) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:16]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:150]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:139]];
        }
        else if (i==37) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:89]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:149]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:145]];
        }
        else if (i==38) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:0]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:151]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:154]];
        }
        else if (i==39) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:0]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:179]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:200]];
        }
        else if (i==40) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:138]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:210]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:241]];
        }
        else if (i==41) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:110]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:176]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:213]];
        }
        else if (i==42) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:64]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:144]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:176]];
        }
        else if (i==43) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:28]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:101]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:158]];
        }
        else if (i==44) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:118]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:143]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:195]];
        }
        else if (i==45) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:119]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:101]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:165]];
        }
        else if (i==46) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:156]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:123]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:178]];
        }
        else if (i==47) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:186]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:143]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:179]];
        }
        else if (i==48) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:215]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:154]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:193]];
        }
        else if (i==49) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:159]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:87]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:146]];
        }
        else if (i==50) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:157]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:34]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:107]];
        }
        else if (i==51) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:190]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:76]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:147]];
        }
        else if (i==52) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:234]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:110]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:160]];
        }
        else if (i==53) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:190]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:31]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:92]];
        }
        else if (i==54) {
            [currentFarbe setFarbcodeR:[NSNumber numberWithInt:222]];
            [currentFarbe setFarbcodeG:[NSNumber numberWithInt:107]];
            [currentFarbe setFarbcodeB:[NSNumber numberWithInt:121]];
        }
        //NSLog(@"currentFarbe = %@", currentFarbe);
    
    
    }
    
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithContentsOfURL:URL];
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

-(void) emptyDataContext
{
	// Get all recipes, It's the top level object and the reference cascade deletion downward
	//NSMutableArray* mutableFetchResults = [CoreDataHelper getObjectsFromContext:@"Rezept" :@"Id" :NO :managedObjectContext];
    NSMutableArray* mutableFetchResults = [CoreDataHelper getObjectsFromContext:@"App" :@"Titel" :NO :managedObjectContext];
	// Delete all Recipes
	for (int i = 0; i < [mutableFetchResults count]; i++) {
		[managedObjectContext deleteObject:[mutableFetchResults objectAtIndex:i]];
		
	}
    
	
	// Update the data model effectivly removing the objects we removed above.
	NSError *error;
	if (![managedObjectContext save:&error]) {
		
		// Handle the error.
		NSLog(@"%@", [error domain]);
	}
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName) {
        elementName = qName;
    }
	
	// If it's the start of the XML, remove everything we've stored so far
	if ([elementName isEqualToString:@"App"])
	{
		[self emptyDataContext];
        
        //get App Title
        currentApp = (App *)[NSEntityDescription insertNewObjectForEntityForName:@"App" inManagedObjectContext:managedObjectContext];
        [currentApp setTitel:[attributeDict objectForKey:@"Titel"]];
        
        [currentApp setAppVar1Links:[attributeDict objectForKey:@"AppVar1Links"]];
        [currentApp setAppVar1Rechts:[attributeDict objectForKey:@"AppVar1Rechts"]];
        [currentApp setAppVar2Links:[attributeDict objectForKey:@"AppVar2Links"]];
        [currentApp setAppVar2Mitte:[attributeDict objectForKey:@"AppVar2Mitte"]];
        [currentApp setAppVar2Rechts:[attributeDict objectForKey:@"AppVar2Rechts"]];
        [currentApp setAppVar3Links:[attributeDict objectForKey:@"AppVar3Links"]];
        [currentApp setAppVar3Rechts:[attributeDict objectForKey:@"AppVar3Rechts"]];
        [currentApp setFilterlabel1:[attributeDict objectForKey:@"Filterlabel1"]];
        [currentApp setFilterlabel2:[attributeDict objectForKey:@"Filterlabel2"]];
        [currentApp setFilterlabel3:[attributeDict objectForKey:@"Filterlabel3"]];
        [currentApp setFilterlabel4:[attributeDict objectForKey:@"Filterlabel4"]];
        [currentApp setFilterlabel5:[attributeDict objectForKey:@"Filterlabel5"]];
        [currentApp setFilterlabel6:[attributeDict objectForKey:@"Filterlabel6"]];
        [currentApp setFilterlabel7:[attributeDict objectForKey:@"Filterlabel7"]];
        
		return;
	}
    
	// Create a new Recipe
    if ([elementName isEqualToString:@"Rezept"]) 
	{
        currentRecipe = (Rezept *)[NSEntityDescription insertNewObjectForEntityForName:@"Rezept" inManagedObjectContext:managedObjectContext];
		[currentRecipe setId:[attributeDict objectForKey:@"id"]];
        
		
        return;
    } else if ([elementName isEqualToString:@"Titel"]) {
        self.contentsOfCurrentProperty = [NSMutableString string];
    } else if ([elementName isEqualToString:@"Schwierigkeit"]) {
        [currentRecipe setSchwierigkeit:[attributeDict objectForKey:@"Wert"]];
    } else if ([elementName isEqualToString:@"Zutaten"]) {
        ignoreValue = NO;
        currentZutaten1 = (Zutaten *)[NSEntityDescription insertNewObjectForEntityForName:@"Zutaten" inManagedObjectContext:managedObjectContext];
        
        currentZutaten = currentZutaten1;
    } else if ([elementName isEqualToString:@"Zutaten2"]) {
        currentZutaten2 = (Zutaten2 *)[NSEntityDescription insertNewObjectForEntityForName:@"Zutaten2" inManagedObjectContext:managedObjectContext];
        
        currentZutaten = currentZutaten2;
    } else if ([elementName isEqualToString:@"Zutatengruppe"]) {
        if (!ignoreIngredientGroup)
            ignoreIngredientGroup = YES;
        else
            return;
    } else if ([elementName isEqualToString:@"Zutat"]) {
        currentIngredient = (Zutat *)[NSEntityDescription insertNewObjectForEntityForName:@"Zutat" inManagedObjectContext:managedObjectContext];
        [currentIngredient setIndex:[NSNumber numberWithInt:[[attributeDict objectForKey:@"Index"] intValue]]];
        [currentIngredient setRezepttitel:currentRecipe.Titel];
    } else if ([elementName isEqualToString:@"Menge"]) {
        self.contentsOfCurrentProperty = [NSMutableString string];
    } else if ([elementName isEqualToString:@"Einheit"]) {
        self.contentsOfCurrentProperty = [NSMutableString string];
    } else if ([elementName isEqualToString:@"Originaltext"]) {
        self.contentsOfCurrentProperty = [NSMutableString string];
    } else if ([elementName isEqualToString:@"Text"]) {
        self.contentsOfCurrentProperty = [NSMutableString string];
    } else if ([elementName isEqualToString:@"Wert"] && !ignoreValue) {
        self.contentsOfCurrentProperty = [NSMutableString string];
        [currentIngredient setPluraltext:[attributeDict objectForKey:@"normplural"]];
    } else if ([elementName isEqualToString:@"Zusatzinformationen"]) {

        [currentRecipe setAppVar1:[attributeDict objectForKey:@"AppVar1"]];
        [currentRecipe setAppVar2:[attributeDict objectForKey:@"AppVar2"]];
        [currentRecipe setAppVar3:[attributeDict objectForKey:@"AppVar3"]];
        [currentRecipe setKalorien:[attributeDict objectForKey:@"Kalorien"]];
        [currentRecipe setZubereitungszeit:[attributeDict objectForKey:@"Zubereitungszeit"]];
        [currentRecipe setGesamtzeit:[attributeDict objectForKey:@"Gesamtzeit"]];
        [currentRecipe setFarbcodeR:[NSNumber numberWithInt:[[attributeDict objectForKey:@"FarbcodeA_R"] intValue]]];
        [currentRecipe setFarbcodeG:[NSNumber numberWithInt:[[attributeDict objectForKey:@"FarbcodeA_G"] intValue]]];
        [currentRecipe setFarbcodeB:[NSNumber numberWithInt:[[attributeDict objectForKey:@"FarbcodeA_B"] intValue]]];
        [currentRecipe setFarbcodeR2:[NSNumber numberWithInt:[[attributeDict objectForKey:@"FarbcodeB_R"] intValue]]];
        [currentRecipe setFarbcodeG2:[NSNumber numberWithInt:[[attributeDict objectForKey:@"FarbcodeB_G"] intValue]]];
        [currentRecipe setFarbcodeB2:[NSNumber numberWithInt:[[attributeDict objectForKey:@"FarbcodeB_B"] intValue]]];
    } else if ([elementName isEqualToString:@"Mengenbasis"]) {
        [currentRecipe setMengenbasisanzahl:[attributeDict objectForKey:@"Anzahl"]];
        [currentRecipe setMengenbasiseinheit:[attributeDict objectForKey:@"Einheit"]];
    } else if ([elementName isEqualToString:@"Kochanleitung"]) {
        currentKochanleitung1 = (Kochanleitung *)[NSEntityDescription insertNewObjectForEntityForName:@"Kochanleitung" inManagedObjectContext:managedObjectContext];
        currentKochanleitung = currentKochanleitung1;
    } else if ([elementName isEqualToString:@"Kochanleitung2"]) {
        currentKochanleitung2 = (Kochanleitung2 *)[NSEntityDescription insertNewObjectForEntityForName:@"Kochanleitung2" inManagedObjectContext:managedObjectContext];
        
        currentKochanleitung = currentKochanleitung2;
    } else if ([elementName isEqualToString:@"Textabsatz"]) {
        if (!inTipEntity) {
            currentTextabsatz = (Textabsatz *)[NSEntityDescription insertNewObjectForEntityForName:@"Textabsatz" inManagedObjectContext:managedObjectContext];
            [currentTextabsatz setNummer:[attributeDict objectForKey:@"Nummer"]];
        }

        self.contentsOfCurrentProperty = [NSMutableString string];
    } else if ([elementName isEqualToString:@"Kurztext"]) {
        if (!ignoreShortText)
            ignoreShortText = YES;
        else
            return;
    } else if ([elementName isEqualToString:@"Ergänzungstext"]) {
        if (!inTipEntity)
            inTipEntity = YES;
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{     
    if (qName) {
        elementName = qName;
    }
    
	// If we're at the end of a recipe, save changes to object model.
	if ([elementName isEqualToString:@"Rezept"]) {
        
		// Sanity check
		if(currentRecipe != nil)
		{
            ignoreValue = YES;
			NSError *error;

			// Store what we imported already
			if (![managedObjectContext save:&error]) {
				
				// Handle the error.
				NSLog(@"%@", [error domain]);
			}
		}
    } else if ([elementName isEqualToString:@"Titel"]) {
        if (!inTipEntity)
            [currentRecipe setTitel:self.contentsOfCurrentProperty];
        else
            [currentRecipe setTipptitel:self.contentsOfCurrentProperty];
        self.contentsOfCurrentProperty = nil;
    } else if ([elementName isEqualToString:@"Menge"]) {
    
        [currentIngredient setMenge:self.contentsOfCurrentProperty];
        
        self.contentsOfCurrentProperty = nil;
    } else if ([elementName isEqualToString:@"Einheit"]) {
        [currentIngredient setEinheit:self.contentsOfCurrentProperty];

        if ([self.contentsOfCurrentProperty isEqualToString:@"Dose"]) {
            [currentIngredient setEinheitplural:@"Dosen"];
            [currentIngredient setEinheitsingular:@"Dose"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Glas"]) {
            [currentIngredient setEinheitplural:@"Gläser"];
            [currentIngredient setEinheitsingular:@"Glas"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Knolle"]) {
            [currentIngredient setEinheitplural:@"Knollen"];
            [currentIngredient setEinheitsingular:@"Knolle"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Kugel"]) {
            [currentIngredient setEinheitplural:@"Kugeln"];
            [currentIngredient setEinheitsingular:@"Kugel"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Messerspitze"]) {
            [currentIngredient setEinheitplural:@"Messerspitzen"];
            [currentIngredient setEinheitsingular:@"Messerspitze"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Prise"]) {
            [currentIngredient setEinheitplural:@"Prisen"];
            [currentIngredient setEinheitsingular:@"Prise"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Scheibe"]) {
            [currentIngredient setEinheitplural:@"Scheiben"];
            [currentIngredient setEinheitsingular:@"Scheibe"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Schote"]) {
            [currentIngredient setEinheitplural:@"Schoten"];
            [currentIngredient setEinheitsingular:@"Schote"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Spitze"]) {
            [currentIngredient setEinheitplural:@"Spitzen"];
            [currentIngredient setEinheitsingular:@"Spitze"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Stange"]) {
            [currentIngredient setEinheitplural:@"Stangen"];
            [currentIngredient setEinheitsingular:@"Stange"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Tasse"]) {
            [currentIngredient setEinheitplural:@"Tassen"];
            [currentIngredient setEinheitsingular:@"Tasse"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Tranche"]) {
            [currentIngredient setEinheitplural:@"Tranchen"];
            [currentIngredient setEinheitsingular:@"Tranche"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Zehe"]) {
            [currentIngredient setEinheitplural:@"Zehen"];
            [currentIngredient setEinheitsingular:@"Zehe"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Zweig"]) {
            [currentIngredient setEinheitplural:@"Zweige"];
            [currentIngredient setEinheitsingular:@"Zweig"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Flasche"]) {
            [currentIngredient setEinheitplural:@"Flaschen"];
            [currentIngredient setEinheitsingular:@"Flasche"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Tüte"]) {
            [currentIngredient setEinheitplural:@"Tüten"];
            [currentIngredient setEinheitsingular:@"Tüte"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Packung"]) {
            [currentIngredient setEinheitplural:@"Packungen"];
            [currentIngredient setEinheitsingular:@"Packung"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Beet"]) {
            [currentIngredient setEinheitplural:@"Beete"];
            [currentIngredient setEinheitsingular:@"Beet"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Dosen"]) {
            [currentIngredient setEinheitplural:@"Dosen"];
            [currentIngredient setEinheitsingular:@"Dose"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Gläser"]) {
            [currentIngredient setEinheitplural:@"Gläser"];
            [currentIngredient setEinheitsingular:@"Glas"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Knollen"]) {
            [currentIngredient setEinheitplural:@"Knollen"];
            [currentIngredient setEinheitsingular:@"Knolle"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Kugeln"]) {
            [currentIngredient setEinheitplural:@"Kugeln"];
            [currentIngredient setEinheitsingular:@"Kugel"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Messerspitzen"]) {
            [currentIngredient setEinheitplural:@"Messerspitzen"];
            [currentIngredient setEinheitsingular:@"Messerspitze"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Prisen"]) {
            [currentIngredient setEinheitplural:@"Prisen"];
            [currentIngredient setEinheitsingular:@"Prise"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Scheiben"]) {
            [currentIngredient setEinheitplural:@"Scheiben"];
            [currentIngredient setEinheitsingular:@"Scheibe"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Schoten"]) {
            [currentIngredient setEinheitplural:@"Schoten"];
            [currentIngredient setEinheitsingular:@"Schote"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Spitzen"]) {
            [currentIngredient setEinheitplural:@"Spitzen"];
            [currentIngredient setEinheitsingular:@"Spitze"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Stangen"]) {
            [currentIngredient setEinheitplural:@"Stangen"];
            [currentIngredient setEinheitsingular:@"Stange"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Tassen"]) {
            [currentIngredient setEinheitplural:@"Tassen"];
            [currentIngredient setEinheitsingular:@"Tasse"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Tranchen"]) {
            [currentIngredient setEinheitplural:@"Tranchen"];
            [currentIngredient setEinheitsingular:@"Tranche"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Zehen"]) {
            [currentIngredient setEinheitplural:@"Zehen"];
            [currentIngredient setEinheitsingular:@"Zehe"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Zweige"]) {
            [currentIngredient setEinheitplural:@"Zweige"];
            [currentIngredient setEinheitsingular:@"Zweig"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Flaschen"]) {
            [currentIngredient setEinheitplural:@"Flaschen"];
            [currentIngredient setEinheitsingular:@"Flasche"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Tüten"]) {
            [currentIngredient setEinheitplural:@"Tüten"];
            [currentIngredient setEinheitsingular:@"Tüte"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Packungen"]) {
            [currentIngredient setEinheitplural:@"Packungen"];
            [currentIngredient setEinheitsingular:@"Packung"];
        } else if ([self.contentsOfCurrentProperty isEqualToString:@"Beete"]) {
            [currentIngredient setEinheitplural:@"Beete"];
            [currentIngredient setEinheitsingular:@"Beet"];
        }
            
        self.contentsOfCurrentProperty = nil;
    } else if ([elementName isEqualToString:@"Originaltext"]) {
        [currentIngredient setOriginaltext:self.contentsOfCurrentProperty];
        self.contentsOfCurrentProperty = nil;
    } else if ([elementName isEqualToString:@"Text"]) {
        [currentIngredient setText:self.contentsOfCurrentProperty];
        self.contentsOfCurrentProperty = nil;
        
        [currentIngredient setRezeptId:currentRecipe.Id];
    } else if ([elementName isEqualToString:@"Wert"] && !ignoreValue) {
        [currentIngredient setListtext:self.contentsOfCurrentProperty];
        self.contentsOfCurrentProperty = nil;
    } else if ([elementName isEqualToString:@"Zutat"]) {
        if (currentZutaten == currentZutaten1)
            [currentZutaten1 addZutatenToZutatObject:currentIngredient];
        else
            [currentZutaten2 addZutaten2ToZutatObject:currentIngredient];
    } else if ([elementName isEqualToString:@"Zutaten"]) {
        ignoreIngredientGroup = NO;
        currentRecipe.RezeptToZutaten = currentZutaten1;
    } else if ([elementName isEqualToString:@"Zutaten2"]) {
        ignoreIngredientGroup = NO;
        currentRecipe.RezeptToZutaten2 = currentZutaten2;
    } else if ([elementName isEqualToString:@"Textabsatz"]) {
        if (!ignoreShortText && !inTipEntity) {
            [currentTextabsatz setText:self.contentsOfCurrentProperty];
            self.contentsOfCurrentProperty = nil;
            
            if (currentKochanleitung == currentKochanleitung1)
                [currentKochanleitung1 addKochanleitungToTextabsatzObject:currentTextabsatz];
            else
                [currentKochanleitung2 addKochanleitung2ToTextabsatzObject:currentTextabsatz];
        } else if (inTipEntity) {
            [currentRecipe setTipptext:self.contentsOfCurrentProperty];
            self.contentsOfCurrentProperty = nil;
        } else {
            ignoreShortText = NO;
            return;
        }
    } else if ([elementName isEqualToString:@"Kochanleitung"]) {
       
        currentRecipe.RezeptToKochanleitung = currentKochanleitung1;
    } else if ([elementName isEqualToString:@"Kochanleitung2"]) {
       
        currentRecipe.RezeptToKochanleitung2 = currentKochanleitung2;
    } else if ([elementName isEqualToString:@"Ergänzungstext"]) {
        
        inTipEntity = NO;
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (self.contentsOfCurrentProperty) {
        [self.contentsOfCurrentProperty appendString:string];
    }
}

-(void)dealloc
{
    [contentsOfCurrentProperty release];
	[managedObjectContext release];
	[super dealloc];
}
@end
