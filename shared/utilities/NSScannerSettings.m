// =============================================================================
//
// Singleton class for maintaining persistent settings for NSScanner.  Allow:
//
//		* Set scanner settings once and the setting will apply to all future
//		  instances of NSScanner.
//
// =============================================================================

#import "NSScannerSettings.h"

@implementation NSScannerSettings

@synthesize loanColumns, holdColumns, minColumns, columnCountMustMatch, ignoreTableHeaderCells, ignoreHTMLScripts;
@dynamic loanColumnsDictionary, holdColumnsDictionary;

- (id) init
{
	self = [super init];
	[self reset];
	return self;
}

- (void) reset
{
	self.loanColumns			= nil;
	self.holdColumns			= nil;
	self.loanColumnsDictionary	= nil;
	self.holdColumnsDictionary	= nil;
	self.minColumns				= 2;
	self.columnCountMustMatch	= YES;
	self.ignoreTableHeaderCells	= YES;
	self.ignoreHTMLScripts		= NO;
}

- (OrderedDictionary *) loanColumnsDictionary
{
	return loanColumnsDictionary;
}

- (void) setLoanColumnsDictionary: (OrderedDictionary *) dictionary
{
	OrderedDictionary *defaultDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"titleAndAuthor",		@"Title",
		@"titleAndAuthor",		@"TITLE",
		@"titleAndAuthor",		@"Title/Author",
		@"titleAndAuthor",		@"Title / Author",
		@"titleAndAuthor",		@"title",
		@"author",				@"Author",
		@"dueDate",				@"Due Date",
		@"dueDate",				@"Due",
		@"dueDate",				@"Date due/Recall date due",
		@"dueDate",				@"STATUS",
		@"dueDate",				@"expiry date",
		@"dueDate",				@"Date due/Time",				// SIRSI - North Vancouver Library
		@"isbn",				@"ISBN",
		@"",					@"Renews Left"
		@"timesRenewed",		@"Renews",						// TalisPrism
		@"timesRenewed",		@"Number of renewals",			// Vubis - us.la.EastBatonRougeParishLibrary
		nil
	];
	
	if (dictionary == nil) dictionary = [OrderedDictionary dictionary];
	loanColumnsDictionary = [dictionary retain];
	[loanColumnsDictionary addEntriesFromDictionary: defaultDictionary];
}

- (OrderedDictionary *) holdColumnsDictionary
{
	return holdColumnsDictionary;
}

- (void) setHoldColumnsDictionary: (OrderedDictionary *) dictionary
{
	OrderedDictionary *defaultDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"titleAndAuthor",		@"Title",
		@"titleAndAuthor",		@"TITLE",
		@"titleAndAuthor",		@"Title/Author",
		@"titleAndAuthor",		@"Title / Author",
		@"titleAndAuthor",		@"title",
		@"titleAndAuthor",		@"Title information",
		@"author",				@"Author",
		@"queueDescription",	@"Position",
		@"queueDescription",	@"STATUS",
		@"queueDescription",	@"Status",
		@"queueDescription",	@"Rank",
		@"queueDescription",	@"Status/Pickup Details",
		@"queueDescription",	@"Availability",
		@"queueDescription",	@"Remark",
		@"queuePosition",		@"Queue number",
		@"queuePosition",		@"Priority",
		@"queuePosition",		@"Place in queue",
		@"expiryDate",			@"Pickup By",
		@"expiryDate",			@"Expires",
		@"expiryDate",			@"Available until",
		@"pickupAt",			@"PICKUP LOCATION",
		@"pickupAt",			@"Pickup Location",
		@"pickupAt",			@"Location",
		@"pickupAt",			@"Pickup at",
		@"pickupAt",			@"Pickup Branch",
		@"pickupAt",			@"Pickup",
		@"pickupAt",			@"Collect at",
		@"pickupAt",			@"Collect From",				// Amilib
		@"pickupAt",			@"Available for pickup at",
		@"pickupAt",			@"Place of Delivery",
		@"isbn",				@"ISBN",
		nil
	];
	
	if (dictionary == nil) dictionary = [OrderedDictionary dictionary];
	holdColumnsDictionary = [dictionary retain];
	[holdColumnsDictionary addEntriesFromDictionary: defaultDictionary];
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static NSScannerSettings *sharedSettings = nil;

+ (NSScannerSettings *) sharedSettings
{
    @synchronized(self)
	{
        if (sharedSettings == nil)
		{
            sharedSettings = [[NSScannerSettings alloc] init];
        }
    }
	
    return sharedSettings;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedSettings == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedSettings;
}

- (id) copyWithZone:(NSZone *)zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (NSUInteger) retainCount
{
	// Denotes an object that cannot be released
    return NSUIntegerMax;
}

- (oneway void) release
{
    // Do nothing
}

- (id) autorelease
{
    return self;
}

@end