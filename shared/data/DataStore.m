#import "DataStore.h"
#import "LibraryProperties.h"
#import "OPAC.h"
#import "HTMLTidySettings.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import "SingleLibrary.h"
#endif

@implementation DataStore

@synthesize context2Thread;

// =============================================================================
#pragma mark -
#pragma mark Refreshing loans/holds

// -----------------------------------------------------------------------------
//
// Determine if a migration is necessary.
//
// -----------------------------------------------------------------------------
+ (BOOL) isMigrationNecessary
{
	NSString *path		= [[NSBundle mainBundle] pathForResource: @"Data" ofType: @"momd"];
	NSURL *momURL		= [NSURL fileURLWithPath: path];
	NSManagedObjectModel *destinationModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL: momURL] autorelease];

	NSError *error							= nil;
//	NSManagedObjectModel *destinationModel	= [NSManagedObjectModel mergedModelFromBundles: nil];
	NSString *applicationSupportDirectory	= [[NSFileManager defaultManager] applicationSupportDirectory];
	
	NSURL *userDataStoreURL			= [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"UserData.sqlite"]];
	NSDictionary *sourceMetadata	= [NSPersistentStoreCoordinator metadataForPersistentStoreOfType: NSSQLiteStoreType URL: userDataStoreURL error: &error];
	if ([destinationModel isConfiguration: nil compatibleWithStoreMetadata: sourceMetadata] == NO)
	{
		[Debug logError: @"UserData.sqlite needs to be migrated"];
		return YES;
	}

	userDataStoreURL				= [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"Libraries.sqlite"]];
	sourceMetadata					= [NSPersistentStoreCoordinator metadataForPersistentStoreOfType: NSSQLiteStoreType URL: userDataStoreURL error: &error];
	if ([destinationModel isConfiguration: nil compatibleWithStoreMetadata: sourceMetadata] == NO)
	{
		[Debug logError: @"Libraries.sqlite needs to be migrated"];
		return YES;
	}
	
	return NO;
}

- (id) init
{
	self = [super init];

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(mergeChangesFromOtherContext:)
		name: NSManagedObjectContextDidSaveNotification object: nil];
	self.context2Thread = nil;
	
	return self;
}

- (void) update
{
	[Debug clearLog];
	
	[Debug log: @"Date:       %@", [[NSDate date] description]												];
	[Debug log: @"OS:         %@", [[NSProcessInfo processInfo] operatingSystemVersionString]				];
	[Debug log: @"LB version: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]	];
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	[Debug log: @"Device:     %@", [[UIDevice currentDevice] name]											];
#endif

	NSMutableDictionary *defaults = [[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] mutableCopy] autorelease];
	[defaults removeObjectForKey: @"SBFormattedPhoneNumber"];
	[defaults removeObjectForKey: @"NSLanguages"];
	[defaults removeObjectForKey: @"AppleLanguages"];
	[defaults removeObjectForKey: @"AppleKeyboards"];
	[defaults removeObjectForKey: @"AppleRecentFolders"];
	[defaults removeObjectForKey: @"ColorSyncDevices"];
	[defaults removeObjectForKey: @"EnergySaverPrefs"];
	[defaults removeObjectForKey: @"NSNavRecentPlaces"];
	[Debug logDetails: [defaults description] withSummary: @"User defaults"];
	[Debug space];
	[Debug space];
	
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	if ([cookieStorage cookieAcceptPolicy] == NSHTTPCookieAcceptPolicyNever)
	{
		[Debug logError: @"Cookies disabled"];
	}
//	[cookieStorage setCookieAcceptPolicy: NSHTTPCookieAcceptPolicyOnlyFromMainDocumentDomain];

	LibraryProperties *libraryProperties = [LibraryProperties libraryProperties];

	// Need to do a periodic library properties update to make sure the settings
	// are kept up to date
//	[self.managedObjectContext lock];
	[libraryProperties update];
	[self save];

// FOR TEST - uncomment to force load library properties
//	[libraryProperties loadIntoStore];

// WORK AROUND - TO REMOVE BAD CARDS
	for (LibraryCard *libraryCard in [self selectLibraryCards])
	{
		if ([self deleteIfBadLibraryCard: libraryCard])
		{
			[self save];
		}
	}

	for (LibraryCard *libraryCard in [self selectLibraryCards])
	{
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		[Debug divider];

		[self prepareLoansForLibraryCard: libraryCard];
		[self prepareHoldsForLibraryCard: libraryCard];

/*	
		[self deleteAllLoansForLibraryCard: libraryCard];
		[self deleteAllHoldsForLibraryCard: libraryCard];

// PHASE II: invalidate then update
//		[self invalidateAllLoansForLibraryCard: libraryCard];
	
		// Create a dummy loan item
		Loan *loan			= [Loan loan];
		loan.title			= @"";
		loan.author			= @"";
		loan.libraryCard	= libraryCard;
		loan.dueDate		= [NSDate distantFuture];
		loan.dummy			= [NSNumber numberWithBool: YES];

		// Create a dummy hold item
		Hold *hold			= [Hold hold];
		hold.title			= @"";
		hold.author			= @"";
		hold.libraryCard	= libraryCard;
		hold.dummy			= [NSNumber numberWithBool: YES];
*/

#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)	
		// Special "demo" user
		if ([SingleLibrary sharedSingleLibrary].enabled
			&& [libraryCard.authentication1 isEqualToString: @"demodemo"])
		{
			[Debug logError: @"Using demo library"];
			libraryCard.libraryPropertyName = @"test.TestLibrary";
		}
#endif
	
		OPAC <OPAC> *opac = [OPAC opacForLibraryCard: libraryCard];
		OPAC <OPAC> *eBookOpac = [OPAC eBookOpacForLibraryCard: libraryCard];
		
		[Debug log: @"Updating [%@] [%@]", libraryCard.name, libraryCard.libraryPropertyName];
		[Debug logDetails: [opac.properties description] withSummary: @"Properties"];
		if ([[opac.properties objectForKey: @"Beta"] boolValue]) [Debug logError: @"BETA"];
		[Debug space];
		
		[Debug setSecretStrings: [NSArray arrayWithObjects: libraryCard.authentication1,
			libraryCard.authentication2, libraryCard. authentication3, nil]];
		
		HTMLTidySettings *htmlTidySettings = [HTMLTidySettings sharedSettings];
		[htmlTidySettings reset];
		htmlTidySettings.noTidyURLs = [opac.properties objectForKey: @"NoTidyURLs"];
		
		@try
		{
			// Do the update
			if ([opac update])
			{
				[self commitLoansForLibraryCard: libraryCard];
				[self commitHoldsForLibraryCard: libraryCard];
				
				libraryCard.lastUpdated = [NSDate date];
				
				[self save];
			}
			else
			{
				[Debug logError: @"Rollback"];
				[self rollback];
			}
			
			if (eBookOpac)
			{
				[Debug space];
				[Debug log: @"Updating eBooks [%@] [%@]", libraryCard.name, libraryCard.libraryPropertyName];
				[Debug logDetails: [eBookOpac.properties description] withSummary: @"Properties"];
				[Debug space];

				if ([eBookOpac update])
				{
					[self commitEBookLoansForLibraryCard: libraryCard];
					[self commitEBookHoldsForLibraryCard: libraryCard];
					
					[self save];
				}
				else
				{
					[Debug logError: @"Rollback eBook"];
					[self rollback];
				}
			}
		}
		@catch (NSException *exception)
		{
			[Debug logError: [exception reason]];
			[Debug logDetails: [exception description] withSummary: @"Exception"];
			[Debug logDetails: [[NSThread callStackSymbols] description] withSummary: @"Stack track"];
			
			[self rollback];
		}
		
		[pool drain];
		
		[Debug space];
		[Debug log: @"Done [%@]", libraryCard.name];
	}
	
	[Debug saveLogToDisk];
	
	// Do some clean up and remove the unused images
	[self deleteUnusedImages];
	[self save];
	
//	[self.managedObjectContext unlock];
	
	// Download images
	if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"BookCovers"] boolValue])
	{
		[Debug log: @"Downloading thumbnails"];
		NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
		[operationQueue setMaxConcurrentOperationCount: 1];
		
		for (Image *image in [self imagesInUse])
		{
			if (image.thumbnail == nil)
			{
//				NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget: image 
//					selector: @selector(downloadImage) object: nil];
				NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget: self 
					selector: @selector(downloadImage:) object: image];
				[operationQueue addOperation: operation];
				[operation release];
			}
		}
		
		[operationQueue release];
	}
}

- (void) downloadImage: (Image *) image
{
//	[self.managedObjectContext lock];
	[image downloadImage];
//	[self.managedObjectContext unlock];
}

- (void) sendReloadNotification
{
//	[[NSNotificationCenter defaultCenter] postNotificationName: @"TablesNeedReloading" object: self];
	[[NSNotificationCenter defaultCenter] postNotificationName: @"BadgesNeedReloading" object: self];
}

// -----------------------------------------------------------------------------
//
// Propagate changes between the two managed object contexts.
//
//		* This is needed otherwise the managed contexts will be out of sync
//		  and the app will blow up if you made changes in both contexts.
//
// -----------------------------------------------------------------------------
- (void) mergeChangesFromOtherContext: (NSNotification *) notification
{
	// Ignore notifications from the calendar
	if ([NSStringFromClass([[notification object] class]) isEqualToString: @"CalManagedObjectContext"]) return;

	if ([NSThread isMainThread])
	{
//		if (context2Thread)
//		{
//			[managedObjectContext2 performSelector: @selector(mergeChangesFromContextDidSaveNotification:)
//				onThread: context2Thread withObject: notification waitUntilDone: YES];
//		}
//		else
//		{
			[managedObjectContext2 mergeChangesFromContextDidSaveNotification: notification];
//		}
	}
	else
	{
		[managedObjectContext1 performSelectorOnMainThread: @selector(mergeChangesFromContextDidSaveNotification:)
			withObject: notification waitUntilDone: YES];
	}
}

////// SPECIAL HACK TO FIX BUG INTRODUCED IN v3.3 ////////
- (BOOL) deleteIfBadLibraryCard: (LibraryCard *) libraryCard
{
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"Loan" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@", libraryCard];
	[request setPredicate: predicate];

	NSError *error; 
	NSArray *objects = [self.managedObjectContext executeFetchRequest: request error: &error];
	if (objects == nil)
	{ 
		[self logError: error withSummary: @"Deleting bad library card [%@]", libraryCard.name];
		[self deleteLibraryCard: libraryCard];
		return YES;
	}
	
	return NO;
}

// =============================================================================
#pragma mark -
#pragma mark Library card

- (NSArray *) selectLibraryCards
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"LibraryCard" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"enabled == TRUE"];
	[request setPredicate: predicate];

	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"ordering" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];

	NSError *error;
	NSArray *libraries = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (libraries == nil)
	{ 
		[self logError: error withSummary: @"failed to selectLibraryCards"];
	}
	
	[request release];

	return libraries;
}

- (NSArray *) selectAllLibraryCards
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"LibraryCard" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"ordering" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];

	NSError *error;
	NSArray *libraries = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (libraries == nil)
	{ 
		[self logError: error withSummary: @"failed to selectAllLibraryCards"];
	}
	
	[request release];

	return libraries;
}

- (NSArray *) libraryCardsNamed: (NSString *) name ignoringLibraryCard: (LibraryCard *) libraryCard
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"LibraryCard" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"name == %@", name];
	[request setPredicate: predicate];

	NSError *error;
	NSArray *libraries = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (libraries == nil)
	{ 
		[self logError: error withSummary: @"failed to fetch libraryCardsNamed [%@]", name];
	}
	
	[request release];

	return libraries;
}

// -----------------------------------------------------------------------------
//
// Fetch library cards.
//
// Notes:
//		* Return all library cards including disabled ones.  This method is
//		  used by the settings so we need to get a list of every card.
//
// -----------------------------------------------------------------------------
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (NSFetchedResultsController *) fetchLibraryCards
{
	// The request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"LibraryCard" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];
	
	// Sort the data
	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"ordering" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];
	
	// Group the sections by libraryCard
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: request
//		managedObjectContext: self.managedObjectContext sectionNameKeyPath: nil cacheName: @"LibraryCard"];
		managedObjectContext: self.managedObjectContext sectionNameKeyPath: nil cacheName: nil];
	[request release];
	
	return [fetchedResultsController autorelease];
}
#endif

- (void) deleteLibraryCard: (LibraryCard *) libraryCard
{
	[self deleteAllLoansForLibraryCard: libraryCard];
	[self deleteAllHoldsForLibraryCard: libraryCard];
	
	[self.managedObjectContext deleteObject: libraryCard];
	[self.managedObjectContext processPendingChanges];
	
	[self sendReloadNotification];
}


- (NSString *) libraryCardNameForOrdering: (int) ordering
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"LibraryCard" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"ordering == %d", ordering];
	[request setPredicate: predicate];

	NSError *error;
	NSArray *libraries = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (libraries == nil)
	{ 
		[self logError: error withSummary: @"failed to libraryCardNameForOrdering [%d]", ordering];
	}
	
	[request release];
	
	if ([libraries count] > 0)
	{
		LibraryCard *libraryCard = [libraries objectAtIndex: 0];
		return libraryCard.name;
	}
	else
	{
		return nil;
	}
}

// -----------------------------------------------------------------------------
//
// Returns OK if the authentication is OK for all the enabled library cards.
//
// -----------------------------------------------------------------------------
- (BOOL) authenticationOKForAllLibraryCards
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"enabled == TRUE and authenticationOK == FALSE"];
	return [self countEntityNamed: @"LibraryCard" predicate: predicate] == 0;
}

// -----------------------------------------------------------------------------
//
// Return the max ordering value.  Used to determine the next ordering value.
//
// Doco: file:///Library/Developer/Shared/Documentation/DocSets/com.apple.adc.documentation.AppleiPhone3_0.iPhoneLibrary.docset/Contents/Resources/Documents/documentation/Cocoa/Conceptual/CoreData/Articles/cdFetching.html
//
// -----------------------------------------------------------------------------
- (int) maxLibraryCardOrdering
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"LibraryCard" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];
	
//	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"deleted == FALSE"];
//	[request setPredicate: predicate];
	
	[request setResultType: NSDictionaryResultType];
	NSExpression *keyPathExpression = [NSExpression expressionForKeyPath: @"ordering"];
	NSExpression *minExpression		= [NSExpression expressionForFunction: @"max:" arguments: [NSArray arrayWithObject: keyPathExpression]];

	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:					@"maxOrdering"];
	[expressionDescription setExpression:			minExpression];
	[expressionDescription setExpressionResultType: NSInteger32AttributeType];
 
	[request setPropertiesToFetch: [NSArray arrayWithObject: expressionDescription]];
 
	NSError *error;
	int maxOrdering = 0;
	NSArray *objects = [self.managedObjectContext executeFetchRequest: request error: &error];
	if (objects == nil)
	{
		[self logError: error withSummary: @"failed to maxLibraryCardOrdering"];
	}
	else
	{
		if ([objects count] > 0)
		{
			maxOrdering = [[[objects objectAtIndex:0] valueForKey: @"maxOrdering"] intValue];
		}
	}
	 
	[expressionDescription release];
	[request release];
	
	return maxOrdering;
}

// =============================================================================
#pragma mark -
#pragma mark Loans

// -----------------------------------------------------------------------------
//
// Fetch loans for the loans table view.
//
// The data is sectioned by library card and sorted by due date.
//
// -----------------------------------------------------------------------------
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (NSFetchedResultsController *) fetchLoans
{
	// The request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"Loan" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard.enabled == TRUE and temporary == FALSE"];
	[request setPredicate: predicate];
	
	// Sort the data
	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"libraryCard.ordering" ascending: YES];
	NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey: @"dummy" ascending: YES];
	NSSortDescriptor *sortDescriptor3 = [[NSSortDescriptor alloc] initWithKey: @"dueDate" ascending: YES];
	NSSortDescriptor *sortDescriptor4 = [[NSSortDescriptor alloc] initWithKey: @"title" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, sortDescriptor2, sortDescriptor3, sortDescriptor4, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];
	[sortDescriptor2 release];
	[sortDescriptor3 release];
	[sortDescriptor4 release];
	
	
	NSError *error;
	NSArray *loans = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (loans == nil)
	{ 
	}
	
	// Group the sections by libraryCard
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: request
//		managedObjectContext: self.managedObjectContext sectionNameKeyPath: @"libraryCard.name" cacheName: @"Loan"];
		managedObjectContext: self.managedObjectContext sectionNameKeyPath: @"libraryCard.ordering" cacheName: nil];
	[request release];
	
	return [fetchedResultsController autorelease];
}
#endif

// -----------------------------------------------------------------------------
//
// For the Mac app.
//
// -----------------------------------------------------------------------------
- (NSArray *) loansForLibraryCard: (LibraryCard *) libraryCard eBook: (BOOL) eBook
{
	// The request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"Loan" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and dummy == FALSE and temporary == FALSE and eBook == %@", libraryCard, [NSNumber numberWithBool: eBook]];
	[request setPredicate: predicate];
	
	// Sort the data
	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"dueDate" ascending: YES];
	NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey: @"title" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, sortDescriptor2, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];
	[sortDescriptor2 release];
	
	NSError *error;
	NSArray *loans = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (loans == nil)
	{ 
		[self logError: error withSummary: @"failed to loansForLibraryCard [%@]", [libraryCard description]];
	}
	
	[request release];
	
	return loans;
}

// -----------------------------------------------------------------------------
//
// For iCal.
//
//		* Items grouped by due date.
//
// -----------------------------------------------------------------------------
- (OrderedDictionary *) loansGroupedByDueDateForLibraryCard: (LibraryCard *) libraryCard
{
	// The request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"Loan" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and dummy == FALSE and temporary == FALSE", libraryCard];
	[request setPredicate: predicate];
	
	// Sort the data
	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"dueDate" ascending: YES];
	NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey: @"title" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, sortDescriptor2, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];
	[sortDescriptor2 release];
	
	NSError *error;
	NSArray *loans = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (loans == nil)
	{ 
		[self logError: error withSummary: @"loansGroupedByDueDateForLibraryCard fetch error [%@]", [libraryCard description]];
	}
	
	[request release];
	
	// Group the loans
	OrderedDictionary *dictionary = [OrderedDictionary dictionary];
	NSDate *prevDueDate = [NSDate distantPast];
	NSMutableArray *groupedLoans = [NSMutableArray array];
	for (Loan *loan in loans)
	{
		if ([loan.dueDate isEqualToDate: prevDueDate] == NO && [groupedLoans count] > 0)
		{
			[dictionary addObject: groupedLoans forKey: prevDueDate];
			groupedLoans = [NSMutableArray array];
		}
		
		[groupedLoans addObject: loan];
		prevDueDate = loan.dueDate;
	}
	
	if ([groupedLoans count] > 0)
	{
		[dictionary addObject: groupedLoans forKey: prevDueDate];
	}

	return dictionary;
}

- (void) deleteAllLoansForLibraryCard: (LibraryCard *) libraryCard
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@", libraryCard];
	[self deleteAll: @"Loan" predicate: predicate];
}

- (void) prepareLoansForLibraryCard: (LibraryCard *) libraryCard
{
	// Make a dummy entry if necessary
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and dummy == TRUE", libraryCard];
	int count = [self countEntityNamed: @"Loan" predicate: predicate];
	if (count == 0)
	{
		// Create a dummy loan item
		Loan *loan			= [Loan loan];
		loan.title			= @"";
		loan.author			= @"";
		loan.libraryCard	= libraryCard;
		loan.dueDate		= [NSDate distantFuture];
		loan.dummy			= [NSNumber numberWithBool: YES];
	}
	
	// Remove any lingering temporary entries
	predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and temporary == TRUE", libraryCard];
	[self deleteAll: @"Loan" predicate: predicate];
}

- (void) commitLoansForLibraryCard: (LibraryCard *) libraryCard
{
	// Remove
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and dummy == FALSE and temporary == FALSE and eBook == FALSE", libraryCard];
	[self deleteAll: @"Loan" predicate: predicate];
	
	// Commit
	predicate		= [NSPredicate predicateWithFormat: @"libraryCard == %@ and temporary == TRUE and eBook == FALSE", libraryCard];
	NSArray *loans	= [self objectsForentityNamed: @"Loan" predicate: predicate];
	
	if (loans)
	{
		for (Loan *loan in loans)
		{
			loan.temporary = [NSNumber numberWithBool: NO];
		}
	}
}

- (void) commitEBookLoansForLibraryCard: (LibraryCard *) libraryCard
{
	// Remove
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and dummy == FALSE and temporary == FALSE and eBook == TRUE", libraryCard];
	[self deleteAll: @"Loan" predicate: predicate];
	
	// Commit
	predicate		= [NSPredicate predicateWithFormat: @"libraryCard == %@ and temporary == TRUE and eBook == TRUE", libraryCard];
	NSArray *loans	= [self objectsForentityNamed: @"Loan" predicate: predicate];
	
	if (loans)
	{
		for (Loan *loan in loans)
		{
			loan.temporary = [NSNumber numberWithBool: NO];
		}
	}
}

// -----------------------------------------------------------------------------
//
// Count the number of overdue items.
//
// -----------------------------------------------------------------------------
- (int) countOverdueLoans
{
	return [self countLoansDueBefore: [NSDate today]];
}

- (int) countLoansDueBefore: (NSDate *) date
{
	int count = 0;
	for (LibraryCard *libraryCard in [self selectLibraryCards])
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat: @"dummy == FALSE and temporary == FALSE and dueDate <= %@  and libraryCard == %@", date, libraryCard];
		count += [self countEntityNamed: @"Loan" predicate: predicate];
	}

	return count;
}

- (int) countLoans
{
	int count = 0;
	for (LibraryCard *libraryCard in [self selectLibraryCards])
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat: @"dummy == FALSE and temporary == FALSE and libraryCard == %@", libraryCard];
		count += [self countEntityNamed: @"Loan" predicate: predicate];
	}
	
	return count;
}

- (OrderedDictionary *) dueDatesForActiveLibraries
{
	// The request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"Loan" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"dummy == FALSE and temporary == FALSE and libraryCard.enabled == TRUE"];
	[request setPredicate: predicate];
	
	NSError *error;
	NSArray *loans = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (loans == nil)
	{ 
		[self logError: error withSummary: @"error on dueDatesForActiveLibraries"];
	}
	
	[request release];
	
	// Get the distinct list of due dates
	NSArray *dueDates = [[loans valueForKeyPath: @"@distinctUnionOfObjects.dueDate"] sortedArrayUsingSelector: @selector(compare:)];
	
	OrderedDictionary *dictionary = [OrderedDictionary dictionary];
	for (NSDate *dueDate in dueDates)
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
			@"dummy == FALSE and temporary == FALSE and libraryCard.enabled == TRUE and dueDate == %@", dueDate];
		int count = [self countEntityNamed: @"Loan" predicate: predicate];
		[dictionary addObject: [NSNumber numberWithInt: count] forKey: dueDate];
	}
	
	return dictionary;
}

// =============================================================================
#pragma mark -
#pragma mark Holds

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (NSFetchedResultsController *) fetchHolds
{
	// The request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"Hold" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard.enabled == TRUE"];
	[request setPredicate: predicate];

	// Sort the data
	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"libraryCard.ordering" ascending: YES];
	NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey: @"dummy" ascending: YES];
	NSSortDescriptor *sortDescriptor3 = [[NSSortDescriptor alloc] initWithKey: @"readyForPickup" ascending: NO];
	NSSortDescriptor *sortDescriptor4 = [[NSSortDescriptor alloc] initWithKey: @"queuePosition" ascending: YES];
	NSSortDescriptor *sortDescriptor5 = [[NSSortDescriptor alloc] initWithKey: @"title" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, sortDescriptor2, sortDescriptor3, sortDescriptor4, sortDescriptor5, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];
	[sortDescriptor2 release];
	[sortDescriptor3 release];
	[sortDescriptor4 release];
	[sortDescriptor5 release];
	
	// Group the sections by libraryCard
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: request
//		managedObjectContext: self.managedObjectContext sectionNameKeyPath: @"libraryCard.name" cacheName: @"Hold"];
		managedObjectContext: self.managedObjectContext sectionNameKeyPath: @"libraryCard.ordering" cacheName: nil];
	[request release];
	
	return [fetchedResultsController autorelease];
}
#endif

// -----------------------------------------------------------------------------
//
// For the Mac app.
//
// -----------------------------------------------------------------------------
- (NSArray *) holdsForLibraryCard: (LibraryCard *) libraryCard readyForPickup: (BOOL) readyForPickup eBook: (BOOL) eBook
{
	// The request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"Hold" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and readyForPickup = %@ and dummy == FALSE and temporary == FALSE and eBook = %@", libraryCard, [NSNumber numberWithBool: readyForPickup], [NSNumber numberWithBool: eBook]];
	[request setPredicate: predicate];
	
	// Sort the data
	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"queuePosition" ascending: YES];
	NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey: @"title" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, sortDescriptor2, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];
	[sortDescriptor2 release];
	
	NSError *error;
	NSArray *holds = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (holds == nil)
	{ 
		[self logError: error withSummary: @"failed to holdsForLibraryCard [%@]", [libraryCard description]];
	}
	
	[request release];
	
	return holds;
}

- (void) deleteAllHoldsForLibraryCard: (LibraryCard *) libraryCard
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@", libraryCard];
	[self deleteAll: @"Hold" predicate: predicate];
}

- (void) prepareHoldsForLibraryCard: (LibraryCard *) libraryCard
{
	// Make a dummy entry if necessary
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and dummy == TRUE", libraryCard];
	int count = [self countEntityNamed: @"Hold" predicate: predicate];
	if (count == 0)
	{
		// Create a dummy hold item
		Hold *hold			= [Hold hold];
		hold.title			= @"";
		hold.author			= @"";
		hold.libraryCard	= libraryCard;
		hold.dummy			= [NSNumber numberWithBool: YES];
	}
	
	// Remove any lingering temporary entries
	predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and temporary == TRUE", libraryCard];
	[self deleteAll: @"Loan" predicate: predicate];
}

- (void) commitHoldsForLibraryCard: (LibraryCard *) libraryCard
{
	// Remove
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and dummy == FALSE and temporary == FALSE and eBook == FALSE", libraryCard];
	[self deleteAll: @"Hold" predicate: predicate];
	
	// Commit
	predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and temporary == TRUE and eBook == FALSE", libraryCard];
	NSArray *holds = [self objectsForentityNamed: @"Hold" predicate: predicate];
	if (holds)
	{
		for (Hold *hold in holds)
		{
			hold.temporary = [NSNumber numberWithBool: NO];
		}
	}
}

- (void) commitEBookHoldsForLibraryCard: (LibraryCard *) libraryCard
{
	// Remove
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and dummy == FALSE and temporary == FALSE and eBook == TRUE", libraryCard];
	[self deleteAll: @"Hold" predicate: predicate];
	
	// Commit
	predicate = [NSPredicate predicateWithFormat: @"libraryCard == %@ and temporary == TRUE and eBook == TRUE", libraryCard];
	NSArray *holds = [self objectsForentityNamed: @"Hold" predicate: predicate];
	if (holds)
	{
		for (Hold *hold in holds)
		{
			hold.temporary = [NSNumber numberWithBool: NO];
		}
	}
}

// -----------------------------------------------------------------------------
//
// Count the number holds ready for pickup.
//
// -----------------------------------------------------------------------------
- (int) countReadyForPickupHolds
{
	int count = 0;
	for (LibraryCard *libraryCard in [self selectLibraryCards])
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat: @"readyForPickup == TRUE and libraryCard == %@", libraryCard];
		count += [self countEntityNamed: @"Hold" predicate: predicate];
	}
	
	return count;
}

// -----------------------------------------------------------------------------
//
// Count the number of holds.
//
// -----------------------------------------------------------------------------
- (int) countHolds
{
	int count = 0;
	for (LibraryCard *libraryCard in [self selectLibraryCards])
	{
		NSPredicate *predicate = [NSPredicate predicateWithFormat: @"dummy == FALSE and temporary == FALSE and libraryCard == %@", libraryCard];
		count += [self countEntityNamed: @"Hold" predicate: predicate];
	}
	
	return count;
}

// =============================================================================
#pragma mark -
#pragma mark History

- (History *) selectHistoryForLoan: (Loan *) loan month: (NSDate *) month
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"History" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"title == %@ and author == %@ and month == %@",
		loan.title, loan.author, month];
	[request setPredicate: predicate];

	NSError *error;
	NSArray *history = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (history == nil)
	{ 
		[self logError: error withSummary: @"failed to selectHistoryForLoan"];
	}
	
	[request release];
	
	return ([history count] > 0) ? [history objectAtIndex: 0] : nil;
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (NSFetchedResultsController *) fetchHistory
{
	// The request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"History" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];
	
	// Sort the data
	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"month" ascending: NO];
	NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey: @"lastUpdated" ascending: NO];
	NSSortDescriptor *sortDescriptor3 = [[NSSortDescriptor alloc] initWithKey: @"title" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, sortDescriptor2, sortDescriptor3, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];
	[sortDescriptor2 release];
	[sortDescriptor3 release];
	
	// Group the sections by libraryCard
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: request
//		managedObjectContext: self.managedObjectContext sectionNameKeyPath: @"month" cacheName: @"History"];
		managedObjectContext: self.managedObjectContext sectionNameKeyPath: @"month" cacheName: nil];
	[request release];
	
	return [fetchedResultsController autorelease];
}
#endif

// TODO: group by month, author, title
- (NSArray *) selectHistoryForMonth: (NSDate *) month
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"History" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"title" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"month == %@", month];
	[request setPredicate: predicate];

	NSError *error;
	NSArray *history = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (history == nil)
	{ 
		[self logError: error withSummary: @"failed to selectHistoryForMonth [%@]", [month description]];
	}
	
	[request release];

	return history;
}

- (NSArray *) selectHistoryMonths
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"History" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSError *error;
	NSArray *histories = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (histories == nil)
	{ 
		[self logError: error withSummary: @"failed to selectHistoryMonths"];
	}
	
	[request release];
	
	// Get the distinct list and reverse sort it
	return [[histories valueForKeyPath: @"@distinctUnionOfObjects.month"] sortedArrayUsingSelector: @selector(reverseCompare:)];
}

// -----------------------------------------------------------------------------
//
// Returns YES if there is history data.
//
// -----------------------------------------------------------------------------
- (int) countHistory
{
	return [self countEntityNamed: @"History" predicate: nil];
}

// =============================================================================
#pragma mark -
#pragma mark Image

- (Image *) selectImageForURI: (NSString *) uri
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"Image" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"uri == %@", uri];
	[request setPredicate: predicate];

	NSError *error;
	NSArray *images = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (images == nil)
	{ 
		[self logError: error withSummary: @"failed to selectImageForURI [%@]", uri];
	}
	
	[request release];
	
	return ([images count] > 0) ? [images objectAtIndex: 0] : nil;
}

// -----------------------------------------------------------------------------
//
// Get all the images in use.
//
// -----------------------------------------------------------------------------
- (NSArray *) imagesInUse
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"Image" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"loan.@count > 0 or hold.@count > 0"];
	[request setPredicate: predicate];

	NSError *error;
	NSArray *images = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (images == nil)
	{ 
		[self logError: error withSummary: @"error to imagesInUse"];
	}
	
	[request release];
	
	return images;
}

- (void) deleteUnusedImages
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"loan.@count == 0 and hold.@count == 0 and history.@count == 0"];
	[self deleteAll: @"Image" predicate: predicate];
}

// =============================================================================
#pragma mark -
#pragma mark Location

// -----------------------------------------------------------------------------
//
// Return a list of the nearby library locations.
//
// -----------------------------------------------------------------------------
- (NSArray *) locationsNearLocation: (CLLocation *) location
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"Location" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	// TODO: handle crossover at meridian & equator
	// Do a rough search. +/- 0.5 degress will give enough for a 30km radius
	CLLocationCoordinate2D coordinate = location.coordinate;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
		@"latitude between {%lf, %lf} and longitude between {%lf, %lf}",
		coordinate.latitude  - 0.5, coordinate.latitude  + 0.5,
		coordinate.longitude - 0.5, coordinate.longitude + 0.5];
	[request setPredicate: predicate];

	NSError *error;
	NSArray *candidateLocations = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (candidateLocations == nil)
	{ 
		[self logError: error withSummary: @"failed to fetch nearby locations"];
	}
	
	[request release];
	
	// Loop through the candidate list and limit to 30 km
	NSMutableArray *locations = [NSMutableArray arrayWithCapacity: [candidateLocations count]];
	for (Location *l in candidateLocations)
	{
		[l setDistanceFromCLLocation: location];
		if (l.distance <= 30000)
		{
			[locations addObject: l];
		}
	}
	
	NSMutableArray *uniqueLocations		= [NSMutableArray arrayWithCapacity: [locations count]];
	NSMutableDictionary *identifiers	= [NSMutableDictionary dictionaryWithCapacity: [locations count]];
	for (Location *l in [locations sortedArrayUsingSelector: @selector(compare:)])
	{
		if ([identifiers objectForKey: l.identifier] == nil)
		{
			[uniqueLocations addObject: l];
			[identifiers setObject: @"" forKey: l.identifier];
		}
	}
	
	return uniqueLocations;
}

- (void) deleteAllLocations
{
	[self deleteAll: @"Location"];
}

// -----------------------------------------------------------------------------
//
// Count the number of libraries.
//
// -----------------------------------------------------------------------------
- (int) countLibraries
{
	return [self countEntityNamed: @"Library" predicate: nil];
}

// =============================================================================
#pragma mark -
#pragma mark Library

- (Library *) selectLibraryForIdentifier: (NSString *) identifier
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"Library" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"identifier == %@", identifier];
	[request setPredicate: predicate];

	NSError *error;
	NSArray *libraries = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (libraries == nil)
	{ 
		[self logError: error withSummary: @"failed to selectLibraryForIdentifier [%@]", identifier];
	}
	
	[request release];
	
	return ([libraries count] > 0) ? [libraries objectAtIndex: 0] : nil;
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (NSFetchedResultsController *) fetchLibraryDrillDownItemForPath: (NSString *) path
{
	// The request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"LibraryDrillDownItem" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"path == %@", path];
	[request setPredicate: predicate];
	
	// Sort the data
	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"isFolder" ascending: NO];
	NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, sortDescriptor2, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];
	[sortDescriptor2 release];
	
	NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest: request
//		managedObjectContext: self.managedObjectContext sectionNameKeyPath: nil cacheName: @"LibraryDrillDownItem"];
		managedObjectContext: self.managedObjectContext sectionNameKeyPath: nil cacheName: nil];
	[request release];
	
	return [fetchedResultsController autorelease];
}
#endif

- (NSArray *) libraryDrillDownItemForPath: (NSString *) path type: (NSString *) type
{
	// The request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: @"LibraryDrillDownItem" inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];
	
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"path == %@ and type == %@", path, type];
	[request setPredicate: predicate];
	
	// Sort the data
	NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey: @"isFolder" ascending: NO];
	NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey: @"name" ascending: YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: sortDescriptor1, sortDescriptor2, nil]; 
	[request setSortDescriptors: sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor1 release];
	[sortDescriptor2 release];
	
	NSError *error;
	NSArray *libraries = [self.managedObjectContext executeFetchRequest: request error: &error];
	if (libraries == nil)
	{
		// Handle error
	}

	[request release];
	
	return libraries;
}

// -----------------------------------------------------------------------------
//
// Return a list of libraries in currently is use.  This function is used by the
// library drop down menu to make it easier to add libraries for the whole
// family.
//
// -----------------------------------------------------------------------------
- (NSArray *) selectLibrariesInUse
{
	NSArray *libraryCards = [self selectLibraryCards];
	
	NSMutableArray *uniqueLibraries		= [NSMutableArray arrayWithCapacity: [libraryCards count]];
	NSMutableDictionary *identifiers	= [NSMutableDictionary dictionaryWithCapacity: [libraryCards count]];
	for (LibraryCard *l in libraryCards)
	{
		if ([identifiers objectForKey: l.libraryPropertyName] == nil)
		{
			Library *library = [self selectLibraryForIdentifier: l.libraryPropertyName];
			if (library)
			{
				[uniqueLibraries addObject: library];
				[identifiers setObject: @"" forKey: l.libraryPropertyName];
			}
		}
	}
	
	return uniqueLibraries;
}

- (void) deleteAllLibraries
{
	[self deleteAll: @"Library"];
}

- (void) deleteAllLibraryDrillDownItems
{
	[self deleteAll: @"LibraryDrillDownItem"];
}

// -----------------------------------------------------------------------------
//
// Delete all drill down items with the specified type.
//
// -----------------------------------------------------------------------------
- (void) deleteLibraryDrillDownItemsWithType: (NSString *) type
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"type == %@", type];
	[self deleteAll: @"LibraryDrillDownItem" predicate: predicate];
}

// -----------------------------------------------------------------------------
//
// Delete all the libraries with the specified type.
//
// -----------------------------------------------------------------------------
- (void) deleteLibrariesWithType: (NSString *) type
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"type == %@", type];
	[self deleteAll: @"Library" predicate: predicate];
}

// -----------------------------------------------------------------------------
//
// Count the number of libraries for the specified type.
//
// -----------------------------------------------------------------------------
- (int) countLibrariesWithType: (NSString *) type
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"type == %@", type];
	return [self countEntityNamed: @"Library" predicate: predicate];
}

// =============================================================================
#pragma mark -
#pragma mark Generic stuff

// -----------------------------------------------------------------------------
//
// Generic count method.
//
// -----------------------------------------------------------------------------
- (int) countEntityNamed: (NSString *) entityName predicate: (NSPredicate *) predicate
{
	// Request from the Loan entity
	NSFetchRequest *request			= [[NSFetchRequest alloc] init];
	NSEntityDescription *entity		= [NSEntityDescription entityForName: entityName inManagedObjectContext: self.managedObjectContext];
	
	// Do a count
	NSExpression *countExpression	= [NSExpression expressionForEvaluatedObject];
	NSArray *arguments				= [NSArray arrayWithObject: countExpression];
	NSExpression *expression		= [NSExpression expressionForFunction: @"count:" arguments: arguments];

	NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
	[expressionDescription setName:					@"countResult"];
	[expressionDescription setExpression:			expression];
	[expressionDescription setExpressionResultType: NSInteger32AttributeType];
	
	// Prepare the request
	[request setResultType:			NSDictionaryResultType];
	[request setEntity:				entity];
	[request setPropertiesToFetch:	[NSArray arrayWithObject: expressionDescription]];
	if (predicate != nil)
	{
		[request setPredicate:		predicate];
	}
 
	// Execute the request
	NSError *error;
	int overdueCount = 0;
	NSArray *objects = [self.managedObjectContext executeFetchRequest: request error: &error];
	if (objects == nil)
	{
		[self logError: error withSummary: @"failed to count entity [%@]", entityName];
	}
	else
	{
		if ([objects count] > 0)
		{
			overdueCount = [[[objects objectAtIndex:0] valueForKey: @"countResult"] intValue];
		}
	}
	 
	[expressionDescription release];
	[request release];
	
	return overdueCount;
}

- (NSArray *) objectsForentityNamed: (NSString *) entityName predicate: (NSPredicate *) predicate
{
	// The request
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: entityName inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];
	
	[request setPredicate: predicate];
	
	NSError *error;
	NSArray *objects = [self.managedObjectContext executeFetchRequest: request error: &error]; 
	if (objects == nil)
	{ 
		[self logError: error withSummary: @"entitiesNamed error [%@] [%@]", entityName, [predicate description]];
	}
	
	[request release];
	
	return objects;
}

- (void) deleteAll: (NSString *) entityName
{
	[self deleteAll: entityName predicate: nil];
}

- (void) deleteAll: (NSString *) entityName predicate: (NSPredicate *) predicate
{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName: entityName inManagedObjectContext: self.managedObjectContext]; 
	[request setEntity: entity];

	if (predicate)
	{
		[request setPredicate: predicate];
	}

	NSError *error; 
	NSArray *objects = [self.managedObjectContext executeFetchRequest: request error: &error];
	if (objects == nil)
	{ 
		[self logError: error withSummary: @"failure in deleteAll: [%@] predicate: [%@]", entityName, [predicate description]];
	}
	
	[request release];
	
	for (NSManagedObject *object in objects)
	{
		[self.managedObjectContext deleteObject: object];
	}
	
	[self.managedObjectContext processPendingChanges];
}

// =============================================================================
#pragma mark -
#pragma mark Commit/rollback

- (void) save
{
	if ([self.managedObjectContext hasChanges] == NO) return;
	
	NSError *error;
	if ([self.managedObjectContext save: &error] == NO)
	{
		// On error try and log the information to the debug
		[self logError: error withSummary: @"failed to save"];
	
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		// Display an alert dialog to let the user know that something went wrong.
		// This problem is usually caused by an incompatible schema so reinstalling
		// the application will fix it
		UIAlertView *alert	= [[[UIAlertView alloc] init] autorelease];
		alert.title			= @"Whoops, Library Books just crashed";
		alert.message		= @"If this problem happens again try reinstalling the application.";
		alert.delegate		= self;
		
		[alert addButtonWithTitle: @"OK"];
		[alert show];
#else
	exit(-1);
#endif
	}
	
	[self sendReloadNotification];
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (void) alertView: (UIAlertView *) alertView didDismissWithButtonIndex: (NSInteger) buttonIndex
{
	// User acknowledged alert dialog so we can exit now
	exit(-1);
}
#endif

- (void) rollback
{
    if (self.managedObjectContext == nil) return;
	[self.managedObjectContext rollback];
}

- (void) logError:(NSError *) error withSummary: (NSString *) summaryFormat, ...
{
	// Build up the summary string
	va_list arguments;
	va_start(arguments, summaryFormat);
	NSString *summary = [[[NSString alloc] initWithFormat: summaryFormat arguments: arguments] autorelease];
	va_end(arguments);

	[Debug log: @"Store - %@ - %@", summary, [error localizedDescription]];
	NSArray* detailedErrors = [[error userInfo] objectForKey: NSDetailedErrorsKey];
	if (detailedErrors != nil && [detailedErrors count] > 0)
	{
		for (NSError* detailedError in detailedErrors)
		{
			NSLog(@"Store - error - %@", [detailedError userInfo]);
			[Debug logDetails: [[detailedError userInfo] description] withSummary: @"Store - error"];
		}
	}
	else
	{
		NSLog(@"%@", [error userInfo]);
		[Debug logDetails: [[error userInfo] description] withSummary: @"Store - error"];
	}
	
	[Debug saveLogToDisk];
}

// =============================================================================
#pragma mark -
#pragma mark Core data stuff

// -----------------------------------------------------------------------------
//
// Returns the managed object context for the application.
//
// * If the context doesn't already exist, it is created and bound to the
//   persistent store coordinator for the application.
// * Uses a different managed object context for the update thread.
//
// -----------------------------------------------------------------------------
- (NSManagedObjectContext *) managedObjectContext
{
	if ([NSThread isMainThread])
	{
		if (managedObjectContext1 == nil)
		{
			managedObjectContext1 = [[NSManagedObjectContext alloc] init];
			[managedObjectContext1 setPersistentStoreCoordinator: self.persistentStoreCoordinator];
		}
		
		NSAssert(managedObjectContext1 != nil, @"managedObjectContext1 is nil");
		return managedObjectContext1;
	}
	else
	{
		if (managedObjectContext2 == nil)
		{
			managedObjectContext2 = [[NSManagedObjectContext alloc] init];
			[managedObjectContext2 setPersistentStoreCoordinator: self.persistentStoreCoordinator];
		}
		
		NSAssert(managedObjectContext2 != nil, @"managedObjectContext2 is nil");
		return managedObjectContext2;
	}
}

// -----------------------------------------------------------------------------
//
// Returns the managed object model for the application.
//
// If the model doesn't already exist, it is created by merging all of the models
// found in the application bundle.
//
// -----------------------------------------------------------------------------
- (NSManagedObjectModel *) managedObjectModel
{
	if (managedObjectModel == nil)
	{
//		managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: nil] retain];
		
		NSString *path		= [[NSBundle mainBundle] pathForResource: @"Data" ofType: @"momd"];
		NSURL *momURL		= [NSURL fileURLWithPath: path];
		managedObjectModel	= [[NSManagedObjectModel alloc] initWithContentsOfURL: momURL];
	}
	
	return managedObjectModel;
}

// -----------------------------------------------------------------------------
//
// Returns the persistent store coordinator for the application.
//
// If the coordinator doesn't already exist, it is created and the application's
// store added to it.
//
// Notes:
//		* We have to configurations:
//			* UserData  - for storing loans, holds and library cards
//			* Libraries - for storing the library list
//		* Use the editor to assign each entity to a configuration.
//
// -----------------------------------------------------------------------------
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil)
	{
        return persistentStoreCoordinator;
    }

	NSError *error;
	persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: self.managedObjectModel];
	NSString *applicationSupportDirectory = [[NSFileManager defaultManager] applicationSupportDirectory];
	
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithBool: YES], NSMigratePersistentStoresAutomaticallyOption,
//		[NSNumber numberWithBool: YES], NSInferMappingModelAutomaticallyOption,
		nil
	];
	
	// UserData.sqlite
	//
	// Need to add persistent store twice.  Once with nil configuration
	// to do a sucessful migration and then again to load the data properly.
	NSURL *userDataStoreURL = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"UserData.sqlite"]];
    if ([persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
		configuration: nil URL: userDataStoreURL options: options error: &error] == NO)
	{
		[Debug logDetails: [error description] withSummary: @"Error loading UserData.sqlite (1)"];
    }
    if ([persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
		configuration: @"UserData" URL: userDataStoreURL options: nil error: &error] == NO)
	{
		[Debug logDetails: [error description] withSummary: @"Error loading UserData.sqlite (2)"];
    }
	
	// Libraries.sqlite
	NSURL *librariesStoreURL = [NSURL fileURLWithPath: [applicationSupportDirectory stringByAppendingPathComponent: @"Libraries.sqlite"]];
    if ([persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
		configuration: nil URL: librariesStoreURL options: options error: &error] == NO)
	{
		[Debug logDetails: [error description] withSummary: @"Error loading Libraries.sqlite (1)"];
    }
    if ([persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType
		configuration: @"Libraries" URL: librariesStoreURL options: options error: &error] == NO)
	{
		[Debug logDetails: [error description] withSummary: @"Error loading Libraries.sqlite (2)"];
    }
	
	NSAssert(persistentStoreCoordinator != nil, @"persistentStoreCoordinator is nil");
    return persistentStoreCoordinator;
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static DataStore *sharedDataStore = nil;

+ (DataStore *) sharedDataStore
{
    @synchronized(self)
	{
        if (sharedDataStore == nil)
		{
            sharedDataStore = [[DataStore alloc] init];
        }
    }
	
    return sharedDataStore;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedDataStore == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedDataStore;
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