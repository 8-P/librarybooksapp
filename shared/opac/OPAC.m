// -----------------------------------------------------------------------------
//
// This is the library superclass.  All library implementations derive from
// this.
//
// -----------------------------------------------------------------------------

#import "OPAC.h"
#import "Image.h"
#import "History.h"
#import "RegexKitLite.h"
#import "LibraryProperties.h"

@implementation OPAC

@synthesize name, catalogueURL, myAccountCatalogueURL, webPageURL, openingHoursURL, loansTableColumns, holdsTableColumns, libraryCard, authenticationCount, extraAuthenticationAttributes;
@synthesize authentication1Title, authentication2Title, authentication3Title;
@synthesize authentication1Key, authentication2Key, authentication3Key;
@synthesize authentication1IsSecure, authentication2IsSecure, authentication3IsSecure;
@synthesize authentication1Required, authentication2Required, authentication3Required;
@synthesize authentication1IsNumber, authentication2IsNumber, authentication3IsNumber;
@dynamic properties, authenticationAttributes, dateFormat;
@synthesize loansCount, holdsCount;

// -----------------------------------------------------------------------------

+ (OPAC <OPAC> *) opacForProperties: (NSDictionary *) properties
{	
	NSString *className			= [properties objectForKey: @"Class"];
	Class class					= NSClassFromString(className);
	OPAC <OPAC> *library		= [[class alloc] initWithProperties: properties];
	
	return [library autorelease];
}

+ (OPAC<OPAC> *) opacForIdentifier: (NSString *) identifier
{
	if (identifier == nil) return nil;
	
	NSMutableDictionary *properties = [[LibraryProperties libraryProperties] libraryPropertiesForIdentifier: identifier];
	return (properties) ? [OPAC opacForProperties: properties] : nil;
}

+ (OPAC<OPAC> *) opacForLibraryCard: (LibraryCard *) libraryCard
{
	OPAC<OPAC> *opac = [OPAC opacForIdentifier: libraryCard.libraryPropertyName];
	if (opac)
	{
		opac.libraryCard = libraryCard;
		
		// Merge in the override properties
		if (libraryCard.overrideProperties)
		{
			NSMutableDictionary	*p = [NSMutableDictionary dictionaryWithDictionary: opac.properties];
			[p addEntriesFromDictionary: [NSKeyedUnarchiver unarchiveObjectWithData: libraryCard.overrideProperties]];
			
			opac.properties = p;
		}
	}
	
	return opac;
}

+ (OPAC<OPAC> *) eBookOpacForIdentifier: (NSString *) identifier
{
	if (identifier == nil) return nil;
	
	NSMutableDictionary *properties = [[LibraryProperties libraryProperties] libraryPropertiesForIdentifier: identifier];
	if (properties)
	{
		NSMutableDictionary *eBookProperties = [properties objectForKey: @"EBook"];	
		if (eBookProperties)
		{
			return [OPAC opacForProperties: eBookProperties];
		}
	}
	
	return nil;
}

+ (OPAC<OPAC> *) eBookOpacForLibraryCard: (LibraryCard *) libraryCard
{
	OPAC<OPAC> *opac = [OPAC eBookOpacForIdentifier: libraryCard.libraryPropertyName];
	if (opac)
	{
		opac.libraryCard = libraryCard;
		
		// Merge in the override properties
//		if (libraryCard.overrideProperties)
//		{
//			NSMutableDictionary	*p = [NSMutableDictionary dictionaryWithDictionary: opac.properties];
//			[p addEntriesFromDictionary: [NSKeyedUnarchiver unarchiveObjectWithData: libraryCard.overrideProperties]];
//			
//			opac.properties = p;
//		}
	}
	
	return opac;
}

- (id) init
{
	self = [super init];

	dateParser		= [[DateParser dateParser] retain];
	dataStore		= [DataStore sharedDataStore];
	browser			= [[Browser browser] retain];
	scannerSettings = [[NSScannerSettings sharedSettings] retain];
	loansCount		= 0;
	holdsCount		= 0;
	
	return self;
}

- (id) initWithProperties: (NSDictionary *) newProperties
{
	self = [self init];

	self.properties = newProperties;
	
	return self;
}

- (NSDictionary *) properties
{
	return properties;
}

- (void) setProperties: (NSDictionary *) newProperties
{
	[properties release];
	properties = [newProperties retain];

	self.name			= [properties objectForKey: @"Name"];	
	self.catalogueURL	= [URL URLWithString: [properties objectForKey: @"CatalogueURL"]];
	self.webPageURL		= [URL URLWithString: [properties objectForKey: @"WebPageURL"]];
	self.openingHoursURL= [URL URLWithString: [properties objectForKey: @"OpeningHoursURL"]];
	self.dateFormat		= [properties objectForKey: @"DateFormat"];
	
	NSString *myAccountCatalogueURLString = [properties objectForKey: @"MyAccountCatalogueURL"];
	self.myAccountCatalogueURL = (myAccountCatalogueURLString) ? [URL URLWithString: myAccountCatalogueURLString]
		: self.catalogueURL;
		
	NSString *loansTableColumnsString = [properties objectForKey: @"LoansTableColumns"];
	if (loansTableColumnsString) self.loansTableColumns = [loansTableColumnsString componentsSeparatedByString: @","];
	
	NSString *holdsTableColumnsString = [properties objectForKey: @"HoldsTableColumns"];
	if (holdsTableColumnsString) self.holdsTableColumns = [holdsTableColumnsString componentsSeparatedByString: @","];
	
	[scannerSettings reset];
	
	// Save the authentication stuff
	NSArray *authentication = [properties objectForKey: @"Authentication"];
	authenticationCount = [authentication count];
	
	if (authenticationCount >= 1)
	{
		NSDictionary *authentication1	=  [authentication  objectAtIndex: 0];
		self.authentication1Title		=  [authentication1 objectForKey:  @"Title"];
		self.authentication1Key			=  [authentication1 objectForKey:  @"Key"];
		authentication1IsSecure			= [[authentication1 objectForKey:  @"IsSecure"] boolValue];
		authentication1Required			= [[authentication1 objectForKey:  @"Required"] boolValue];
		authentication1IsNumber			= [[authentication1 objectForKey:  @"IsNumber"] boolValue];
	}

	if (authenticationCount >= 2)
	{
		NSDictionary *authentication2	=  [authentication  objectAtIndex: 1];
		self.authentication2Title		=  [authentication2 objectForKey:  @"Title"];
		self.authentication2Key			=  [authentication2 objectForKey:  @"Key"];
		authentication2IsSecure			= [[authentication2 objectForKey:  @"IsSecure"] boolValue];
		authentication2Required			= [[authentication2 objectForKey:  @"Required"] boolValue];
		authentication2IsNumber			= [[authentication2 objectForKey:  @"IsNumber"] boolValue];
	}
	
	if (authenticationCount >= 3)
	{
		NSDictionary *authentication3	=  [authentication  objectAtIndex: 2];
		self.authentication3Title		=  [authentication3 objectForKey:  @"Title"];
		self.authentication3Key			=  [authentication3 objectForKey:  @"Key"];
		authentication3IsSecure			= [[authentication3 objectForKey:  @"IsSecure"] boolValue];
		authentication3Required			= [[authentication3 objectForKey:  @"Required"] boolValue];
		authentication3IsNumber			= [[authentication3 objectForKey:  @"IsNumber"] boolValue];
	}
}

- (void) dealloc
{
	[properties release];
	[name release];
	[catalogueURL release];
	[webPageURL release];
	[openingHoursURL release];
	
	[dataStore release];
	[dateParser release];
	
	[authentication1Title release];
	[authentication2Title release];
	[authentication3Title release];

	[authentication1Key release];
	[authentication2Key release];
	[authentication3Key release];
	
	[browser release];
	[scannerSettings release];

	[super dealloc];
}

// -----------------------------------------------------------------------------
//
// Check for wrong login/password.
//
// -----------------------------------------------------------------------------
- (BOOL) authenticationOK
{
	NSArray *errorStrings = [NSArray arrayWithObjects:
		@"Login failed",
		@"Your login has failed",								// Horizon - Hume Library
		@"Access denied",										// SIRSI - Yarra Plenty Regional Library
		@"Incorrect library card number or PIN",				// SIRSI - Toronto Public Library
		@"Invalid login",										// SIRSI - LINCC
		@"Login entered incorrectly",							// SIRSI - CAFE/Waukesha County
		@"the login you've entered is incorrect",				// SIRSI - SAILS
		@"Authentication Failed",								// SIRSI - Cincinnati
		@"Please enter a valid library card number and PIN",	// SIRSI - MAIN
		@"unable to provide you access",						// SIRSI - Lake Forest
		@"Login Attempt Failed",								// SIRSI - CLEVNET
		@"Invalid ID or PIN",									// Spydus
		@"Borrower has not been assigned a PIN",				// Spydus
		@"Sorry, the information you submitted was invalid",	// Millenium
		@"You have entered invalid account information",		// Millenium - us.va.ArlingtonPublicLibrary
		@"Sorry, cannot locate your record",					// Millenium - ca.sa.SaskatchewanLibraries
		@"Invalid patron ID or password",						// CARLweb - Contra Costa County Library
		@"Your attempt to log in was unsuccessful",				// CARLweb - Chicago Public Library
		@"Invalid entry. Please try again.",					// CARLweb2 - Monroe County NY
		@"Sorry, your barcode could not be located",			// Horizon - Hennepin County Library
		@"Invalid user number",									// Libero - Woollahra Library
		@"Invalid library card",								// Bookit - Varmdo Kommunbibliotek
		@"Invalid card",										// Bookit - Varmdo Kommunbibliotek
		@"LOGIN_FAILED",										// Evergreen
		@"Invalid username or password",						// BiblioCommons
		@"The system was unable to log you on",					// Polaris
		@"invalid barcode",										// Polaris - us.in.LakeCountyPublicLibrary
		@"Could not authenticate",								// AquaBrowser
		@"information you entered is invalid",					// us.oh.ColumbusMetropolitanLibrary
		@"login details have not been recognised by the system",// TalisPrism
		@"Invalid Username or PIN",								// Atriuum
		@"Password do not match our records",					// Phoenix Public Library (username login)
		@"patron record was not found",							// Phoenix Public Library (card # login)
		@"Unrecognized card #",									// us.ny.QueensLibrary
		@"Invalid Library Card",								// Overdrive
		@"Invalid UserID",										// NEBIS
		@"Library card barcode is not entered correctly",		// Vubis - us.la.EastBatonRougeParishLibrary
		@"Incorrect Oxford username or password",				// BoleianLibraries - uk.BodleianLibraries
		@"The library card number or PIN you entered is incorrect", // VuFind - us.pa.FreeLibraryOfPhiladelphia
		nil
	];
	
	NSArray *headErrorStrings = [NSArray arrayWithObjects:
		@"Invalid username or password",						// BiblioCommons
		@"The username or PIN is incorrec",						// BiblioCommons - ca.on.OttawaPublicLibrary
		nil
	];
	
	NSArray *rawHTMLErrorStrings = [NSArray arrayWithObjects:
		@"nicht korrekt oder keine Benutzerdaten vorhanden",	// SISIS - de.UniversitatsbibliothekDortmund
		nil
	];

	// Search for the error string
	BOOL authenticationOK = YES;
	NSString *text = [[browser.scanner string] stringWithoutHTML];
	for (NSString *errorString in errorStrings)
	{
		if ([text hasSubString: errorString] == YES)
		{
			authenticationOK = NO;
			break;
		}
	}
	
	// Try checking the <head>.  This handles javascript based error popups
	if (authenticationOK)
	{
		text = [[browser.scanner head].scanner string];
		for (NSString *errorString in headErrorStrings)
		{
			if ([text hasSubString: errorString] == YES)
			{
				authenticationOK = NO;
				break;
			}
		}
	}
	
	// Check the whole page including HTML
	if (authenticationOK)
	{
		text = [browser.scanner string];
		for (NSString *errorString in rawHTMLErrorStrings)
		{
			if ([text hasSubString: errorString] == YES)
			{
				authenticationOK = NO;
				break;
			}
		}
	}
	
	libraryCard.authenticationOK = [NSNumber numberWithBool: authenticationOK];
	if (authenticationOK == NO) [Debug logError: @"Authentication failure"];
	
	return authenticationOK;
}

- (Loan *) addLoan: (NSDictionary *) row
{
	NSString *title			= nil;
	NSString *author		= nil;
	NSString *isbn			= nil;
	NSDate *dueDate			= nil;
	NSNumber *timesRenewed	= [NSNumber numberWithInt: 0];
	
	for (NSString *column in row)
	{
		NSString *value = [row objectForKey: column];
		
		// Ignore NSNull values that may be produced by the JSON decoder
		if ([value isKindOfClass: [NSNull class]]) continue;
		
		if      ([column isEqualToString: @"title"])			title			= value;
		else if ([column isEqualToString: @"author"])			author			= value;
		else if ([column isEqualToString: @"isbn"])				isbn			= value;
		else if ([column isEqualToString: @"dueDate"])			dueDate			= [self parseDueDate: value];
		else if ([column isEqualToString: @"timesRenewed"])
		{
			timesRenewed = [NSNumber numberWithInt: [value intValue]];
			if ([timesRenewed intValue] < 0)
			{
				timesRenewed = [NSNumber numberWithInt: 0];
			}
		}
		else if ([column isEqualToString: @"titleAndAuthor"])
		{
			// Some systems combine the title and author information so we break
			// it up.  Note that we look for spaces before and after the slash (i.e. " / ")
			[value splitStringOnLast: @" / " intoLeft: &title intoRight: &author]
				|| [value splitStringOnLast: @" /, " intoLeft: &title intoRight: &author];
		}
		else if ([column isEqualToString: @"titleUptoSlash"])
		{
			// Splt the string but drop the author info.  Some catalogue systems
			// just store useless author information
			NSString *dummy;
			[value splitStringOnLast: @" / " intoLeft: &title intoRight: &dummy];
		}
	}
		
	// Don't create the loan if we have invalid values
	if (title == nil || [title isMatchedByRegex: @"^\\s*$"] || dueDate == nil) return nil;
	
	// Merge in the titleExtension column.  Long titleExtensions are not merged
	// in
	NSString *titleExtension = [row objectForKey: @"titleExtension"];
	if (titleExtension && [titleExtension length] < 20) title = [NSString stringWithFormat: @"%@ %@", title, titleExtension];
	
	Loan *loan			= [Loan loan];
	loan.title			= [self normaliseTitle: title];
	loan.author			= [self normaliseAuthor: author];
	loan.isbn			= [isbn nilIfEmpty];
	loan.dueDate		= dueDate;
	loan.image			= [Image imageForLoan: loan];
	loan.libraryCard	= libraryCard;
	loan.temporary		= [NSNumber numberWithBool: YES];
	loan.timesRenewed	= timesRenewed;

	// Update the history as well
	[History historyFromLoan: loan];
	
	loansCount++;
	
	return loan;
}

- (void) addLoans: (NSArray *) rows
{
	int count = 0;
	for (NSDictionary *row in rows)
	{
		Loan *loan = [self addLoan: row];
		if (loan)
		{
			[Debug log: [loan description]];
			count++;
		}
	}
	
	[Debug log: @"Loans - [%d] loans", count];
	[Debug space];
}

- (void) addEBookLoans: (NSArray *) rows
{
	int count = 0;
	for (NSDictionary *row in rows)
	{
		Loan *loan = [self addLoan: row];
		if (loan)
		{
			// Mark as eBook loan
			loan.eBook = YES;
		
			[Debug log: [loan description]];
			count++;
		}
	}
	
	[Debug log: @"eBook Loans - [%d] loans", count];
	[Debug space];
}

- (Hold *) addHold: (NSDictionary *) row
{
	NSString *title					= nil;
	NSString *author				= nil;
	NSString *isbn					= nil;
	NSString *queueDescription		= nil;
	NSNumber *queuePosition			= [NSNumber numberWithInt: -1];
	NSString *queuePositionString	= nil;
	NSString *pickupAt				= nil;
	NSNumber *readyForPickup		= [NSNumber numberWithBool: NO];
	NSDate *expiryDate				= nil;

	for (NSString *column in row)
	{
		NSString *value = [row objectForKey: column];
		
		// Ignore NSNull values that may be produced by the JSON decoder
		if ([value isKindOfClass: [NSNull class]]) continue;
		
		if      ([column isEqualToString: @"title"])				title				= value;
		else if ([column isEqualToString: @"author"])				author				= value;
		else if ([column isEqualToString: @"isbn"])					isbn				= value;
		else if ([column isEqualToString: @"queueDescription"])		queueDescription	= value;
		else if ([column isEqualToString: @"pickupAt"])				pickupAt			= value;
		else if ([column isEqualToString: @"expiryDate"])			expiryDate			= [self parseDueDate: value];
		else if ([column isEqualToString: @"titleAndAuthor"])
		{
			// Some systems combine the title and author information so we break
			// it up.  Note that we look for spaces before and after the slash (i.e. " / ")
			[value splitStringOnLast: @" / " intoLeft: &title intoRight: &author];
		}
		else if ([column isEqualToString: @"titleUptoSlash"])
		{
			// Splt the string but drop the author info.  Some catalogue systems
			// just store useless author information
			NSString *dummy;
			[value splitStringOnLast: @" / " intoLeft: &title intoRight: &dummy];
		}
		else if ([column isEqualToString: @"queuePosition"])
		{
			value = [value stringWithoutHTML];
			value = [value stringByDeletingOccurrencesOfString: @"Position:"];
			value = [value stringByDeletingOccurrencesOfString: @"Your position in the holds queue:"];
	
			if ([value isMatchedByRegex: @"\\d+"])
			{
				queuePosition = [NSNumber numberWithInt: [value intValue]];
			}
			else
			{
				[Debug log: @"Ignoring non integer queuePosition [%@]", value];
				queuePositionString = value;
			}
		}
		else if ([column isEqualToString: @"readyForPickup"])
		{
			if ([value isMatchedByRegex: @"\\b(?i:yes|y)\\b"])
			{
				readyForPickup = [NSNumber numberWithBool: YES];
			}
			else
			{
				readyForPickup = [NSNumber numberWithBool: NO];
			}
		}
	}
	
	// Don't create the loan if we have invalid values
	if (title == nil || [title isMatchedByRegex: @"^\\s*$"]) return nil;
	
	Hold *hold					= [Hold hold];
	hold.title					= [self normaliseTitle: title];
	hold.author					= [self normaliseAuthor: author];
	hold.isbn					= [isbn nilIfEmpty];
	hold.queueDescription		= queueDescription;
	hold.queuePosition			= queuePosition;
	hold.queuePositionString	= queuePositionString;
	hold.pickupAt				= pickupAt;
	hold.image					= [Image imageForHold: hold];
	hold.libraryCard			= libraryCard;
	hold.readyForPickup			= readyForPickup;
	hold.temporary				= [NSNumber numberWithBool: YES];
	hold.expiryDate				= expiryDate;
	
	[hold calculate];
	
	holdsCount++;
	
	return hold;
}

- (void) addHolds: (NSArray *) rows
{
	int count = 0;
	for (NSDictionary *row in rows)
	{
		Hold *hold = [self addHold: row];
		if (hold)
		{
			[Debug log: [hold description]];
			count++;
		}
	}
	
	[Debug log: @"Holds - [%d] holds", count];
	[Debug space];
}

- (void) addEBookHolds: (NSArray *) rows
{
	int count = 0;
	for (NSDictionary *row in rows)
	{
		Hold *hold = [self addHold: row];
		if (hold)
		{
			// Mark as eBook hold
			hold.eBook = YES;
		
			[Debug log: [hold description]];
			count++;
		}
	}
	
	[Debug log: @"eBook Holds - [%d] holds", count];
	[Debug space];
}

// -----------------------------------------------------------------------------
//
// Add holds that are known to be ready for pickup. This is needed because
// so catalogue systems have individual tables for the books that are ready and
// ones waiting.
//
// -----------------------------------------------------------------------------
- (void) addHoldsReadyForPickup: (NSArray *) rows
{
	int count = 0;
	for (NSDictionary *row in rows)
	{
		Hold *hold = [self addHold: row];
		if (hold)
		{
			// Mark the hold as ready for pickup
			hold.readyForPickup	= [NSNumber numberWithBool: YES];
			hold.queuePosition	= [NSNumber numberWithInt: 0];
		
			[Debug log: [hold description]];
			count++;
		}
	}
	
	[Debug log: @"Holds ready for pickup - [%d] holds", count];
	[Debug space];
}

// -----------------------------------------------------------------------------
//
// Due date parsing.
//
// -----------------------------------------------------------------------------
- (NSDate *) parseDueDate: (NSString *) dueDateString
{
	// Clean up:
	//		* Milleninum has a "DUE" prefix
	//		* CAFE (old SIRSI) has a "Due" prefix
	//		* SIRSI has the time in it
	//		* Hennepin has the "Due in ..." suffix
	//		* TALIS has "Due soon" suffix
	//		* us.mn.SaintPaulPublicLibrary has "BILLED" after the due date
	dueDateString = [dueDateString stringByDeletingOccurrencesOfString: @"DUE"];
	dueDateString = [dueDateString stringByDeletingOccurrencesOfString: @"Due"];
	dueDateString = [dueDateString stringByDeletingOccurrencesOfRegex: @",\\d{2}:\\d{2}"];
	dueDateString = [dueDateString stringByDeletingOccurrencesOfRegex: @"Renewed .*$"];
	dueDateString = [dueDateString stringByDeletingOccurrencesOfRegex: @"Due in .*$"];
	dueDateString = [dueDateString stringByDeletingOccurrencesOfRegex: @"soon.*$"];
	dueDateString = [dueDateString stringByDeletingOccurrencesOfRegex: @"BILLED"];
	dueDateString = [dueDateString stringByTrimmingWhitespace];
	
	[dueDateString componentsSeparatedByRegex: @"\\s+"];
	
	// Only grab the first word.
	if ([dateParser.dateFormat hasSubString: @" "] == NO)
	{
		dueDateString = [dueDateString stringUptoFirst: @" "];
	}
	
	// Parse
	NSDate *dueDate = [dateParser dateFromString: dueDateString];
	if (dueDate == nil)
	{
		[Debug logError: @"Failed to parse due date [%@]", dueDateString];
	}
	
	return dueDate;
}

// -----------------------------------------------------------------------------
//
// Clean up the title value:
//
//		* Remove trailing slash: "... /"
//		* Remove trailing colon (Vubis - us.la.EastBatonRougeParishLibrary).
//
// -----------------------------------------------------------------------------
- (NSString *) normaliseTitle: (NSString *) title
{
	if (title == nil) return nil;

	title = [title stringByDeletingOccurrencesOfRegex: @"\\s*[/:]\\s*$"];
	return title;
}

// -----------------------------------------------------------------------------
//
// Clean up the author value:
//
//		* Remove "by ..."
//		* Strip leading and trailing whitespaces.
//
// -----------------------------------------------------------------------------
- (NSString *) normaliseAuthor: (NSString *) author
{
	if (author == nil) return nil;

	author = [author stringByDeletingOccurrencesOfRegex: @"^by\\s+"];
	author = [author stringByTrimmingWhitespace];
	return author;
}

// -----------------------------------------------------------------------------
//
// Return the dictionary of the authentication parameters.  Use the result when
// posting login forms.
//
// -----------------------------------------------------------------------------
- (NSMutableDictionary *) authenticationAttributes
{
	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity: authenticationCount];
	
	if (authenticationCount >= 1) [d setObject: (libraryCard.authentication1) ? libraryCard.authentication1 : @"" forKey: self.authentication1Key];
	if (authenticationCount >= 2) [d setObject: (libraryCard.authentication2) ? libraryCard.authentication2 : @"" forKey: self.authentication2Key];
	if (authenticationCount >= 3) [d setObject: (libraryCard.authentication3) ? libraryCard.authentication3 : @"" forKey: self.authentication3Key];
	
	if (self.extraAuthenticationAttributes)
	{
		[d addEntriesFromDictionary: self.extraAuthenticationAttributes];
	}
	
	return d;
}

- (void) setDateFormat: (NSString *) dateFormat
{
	// Set the date format
	if (!dateFormat)
	{
		[Debug logError: @"Date format not specified in properties"];
	}
	dateParser.dateFormat = dateFormat;
}

- (NSString *) dateFormat
{
	return dateParser.dateFormat;
}

- (BOOL) myAccountEnabled
{
	return [self respondsToSelector: @selector(myAccountURL)];
}

- (BOOL) downloadHoldsEnabled
{
	return [self respondsToSelector: @selector(downloadHoldsURL)];
}

@end 