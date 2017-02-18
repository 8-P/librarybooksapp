#import "LibraryProperties.h"
#import "Location.h"
#import "Library.h"
#import "URL.h"
#import "Debug.h"
#import "LibraryDrillDownItem.h"
#import "NSFileManagerExtras.h"
#import "SharedExtras.h"

#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
#import "SingleLibrary.h"
#endif

@implementation LibraryProperties

// =============================================================================

// Check more often on the desktop version
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	static const int CHECK_INTERVAL = 86400;  // Every day
#else
	static const int CHECK_INTERVAL = 28800;  // Every 8 hours
#endif

NSString * const ConstTypeDefault	= @"default";
NSString * const ConstTypeCustom	= @"custom";
NSString * const ConstTypeGeneric	= @"generic";

// =============================================================================

@dynamic bundleVersion, installedVersion;

+ (LibraryProperties *) libraryProperties
{
	LibraryProperties *libraryProperties = [[[LibraryProperties alloc] init] autorelease];
	return libraryProperties;
}

- (id) init
{
	self = [super init];
	dataStore = [DataStore sharedDataStore];

	return self;
}

- (void) dealloc
{
	[dataStore release];
	[super dealloc];
}

- (NSMutableDictionary *) libraryPropertiesForIdentifier: (NSString *) identifier
{
	Library *library = [dataStore selectLibraryForIdentifier: identifier];
	if (library == nil)
	{
		NSLog(@"Can't find library properties for identifier [%@]", identifier);
		return nil;
	}
	
	return [NSKeyedUnarchiver unarchiveObjectWithData: library.properties];
}

// -----------------------------------------------------------------------------
//
// Load the properties file into the data store.
//
// -----------------------------------------------------------------------------
- (void) loadDefaultLibraries: (NSString *) path
{
	[dataStore deleteLibraryDrillDownItemsWithType: ConstTypeDefault];
	[dataStore deleteLibrariesWithType:             ConstTypeDefault];

	NSDictionary *properties = [NSDictionary dictionaryWithContentsOfFile: path];
	
	[self loadProperties: properties type: ConstTypeDefault];
	
	[dataStore save];
}

- (void) loadCustomLibraries
{
	[dataStore deleteLibraryDrillDownItemsWithType: ConstTypeCustom];
	[dataStore deleteLibrariesWithType:             ConstTypeCustom];

	NSString *path	= [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent: @"Libraries"];
	NSArray *files	= [[NSFileManager defaultManager] contentsOfDirectoryAtPath: path error: nil];
	files			= [files filteredArrayUsingPredicate: [NSPredicate predicateWithFormat: @"self endswith '.plist'"]];
	
	NSMutableDictionary *properties = [NSMutableDictionary dictionary];
	for (NSString *file in files)
	{
		NSString *identifier	= [NSString stringWithFormat: @"custom.%@", [file stringByDeletingOccurrencesOfRegex: @"\\.plist$"]];
		NSString *filePath		= [path stringByAppendingPathComponent: file];
		NSDictionary *settings	= [NSDictionary dictionaryWithContentsOfFile: filePath];

		[Debug logDetails: [settings description] withSummary: @"LibraryProperties.plist - adding custom library [%@]", identifier];
		[properties setObject: settings forKey: identifier];
	}
	
	[self loadProperties: properties type: ConstTypeCustom];
	
	[dataStore save];
}

- (void) loadGenericLibraries
{
	[dataStore deleteLibraryDrillDownItemsWithType: ConstTypeGeneric];
	[dataStore deleteLibrariesWithType:             ConstTypeGeneric];

	NSString *path = [[NSBundle mainBundle] pathForResource: @"LibraryPropertiesGeneric" ofType: @"plist"];
	NSDictionary *properties = [NSDictionary dictionaryWithContentsOfFile: path];
	[self loadProperties: properties type: ConstTypeGeneric];
	
	[dataStore save];
}

- (void) loadProperties: (NSDictionary *) properties type: (NSString *) type
{
	NSMutableDictionary *registeredPaths = [NSMutableDictionary dictionary];

	for (NSString *identifier in properties)
	{
		NSDictionary *p = [properties objectForKey: identifier];
		[self loadProperty: p identifier: identifier registeredPaths: registeredPaths type: type];
		
		// Handle alises
		//
		//		* Aliases a copies of the library but with specific overrides
		//		* Example: a branch library with a different web site URL
		NSDictionary *aliases = [p objectForKey: @"Aliases"];
		if (aliases)
		{
			for (NSString *alias in aliases)
			{
				// Merge in the alias overrides
				NSMutableDictionary *pAlias = [[p mutableCopy] autorelease];
				[pAlias removeObjectForKey: @"Aliases"];
				
				NSDictionary *overrides = [aliases objectForKey: alias];
				[pAlias addEntriesFromDictionary: overrides];
				
				// Group the Name2 and Name attributes together so don't
				// inherit Name2
				if ([overrides objectForKey: @"Name2"] == nil && [overrides objectForKey: @"Name"] != nil)
				{
					[pAlias removeObjectForKey: @"Name2"];
				}
				
				[self loadProperty: pAlias identifier: alias registeredPaths: registeredPaths type: type];
			}
		}
	}
}

- (void) loadProperty: (NSDictionary *) p identifier: (NSString *) identifier registeredPaths: (NSMutableDictionary *) registeredPaths type: (NSString *) type
{
	// Skip disabled libraries
	NSNumber *disabled = [p objectForKey: @"Disabled"];
	if (disabled && [disabled boolValue]) return;

#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
	SingleLibrary *singleLibrary = [SingleLibrary sharedSingleLibrary];	
	if ([singleLibrary isIdentifierEnabled: identifier] == NO) return;
#endif

	// Don't load the library if the OPAC class is not available
	NSString *className	= [p objectForKey: @"Class"];
	if (NSClassFromString(className) == nil)
	{
		[Debug log: @"Not loading library [%@] because class [%@] is not available", identifier, className];
		return;
	}
	
	NSNumber *beta = [NSNumber numberWithBool: NO];
	if ([p objectForKey: @"Beta"]) beta = [p objectForKey: @"Beta"];
	
	// Load the library
	Library *library	= [Library library];
	library.identifier	= identifier;
	library.properties	= [NSKeyedArchiver archivedDataWithRootObject: p];
	library.name		= [p objectForKey: @"Name"];
	library.type		= type;
	library.beta		= beta;

	// Load the locations
	NSArray *locations = [p objectForKey: @"Locations"];
	if (locations)
	{
		NSMutableSet *set = [NSMutableSet set];
		for (NSDictionary *l in locations)
		{
			Location *location	= [Location location];
			location.identifier	= identifier;
			location.latitude	= [l objectForKey: @"Latitude"];
			location.longitude	= [l objectForKey: @"Longitude"];

			[set addObject: location];
		}
		
		library.locations = set;
	}
	
	LibraryDrillDownItem *drillDownItem = [LibraryDrillDownItem libraryDrillDownItem];
	drillDownItem.name					= library.name;
	drillDownItem.name2					= [p objectForKey: @"Name2"];
	drillDownItem.isFolder				= [NSNumber numberWithBool: NO];
	drillDownItem.path					= [p objectForKey: @"Path"];
	drillDownItem.type					= type;
	drillDownItem.imageName				= [p objectForKey: @"ImageName"];
	
	// Add a "BETA" image tag to the beta libraries
	if ([beta boolValue] && drillDownItem.imageName == nil)
	{
		drillDownItem.imageName = @"BetaTag.png";
	}
	
	library.libraryDrillDownItem		= drillDownItem;

	// Create the path folders
	if ([registeredPaths objectForKey: drillDownItem.path] == nil)
	{
		NSString *path = @"/";
		for (NSString *folder in [drillDownItem.path pathComponents])
		{
			if ([folder isEqualToString: @"/"]) continue;
			
			NSString *nextPath = [path stringByAppendingPathComponent: folder];
			
			if ([registeredPaths objectForKey: nextPath] == NO)
			{
				LibraryDrillDownItem *drillDownItem = [LibraryDrillDownItem libraryDrillDownItem];
				drillDownItem.name		= folder;
				drillDownItem.isFolder	= [NSNumber numberWithBool: YES];
				drillDownItem.path		= path;
				drillDownItem.type		= type;
																						
				//NSLog(@"name [%@], path [%@]", drillDownItem.name, path);
				[registeredPaths setObject: @"" forKey: nextPath];
			}
			
			path = nextPath;
		}
	}
}

// -----------------------------------------------------------------------------
//
// This is for doing a one time loading of LibraryProperties.plist from the
// bundle into Libraries.sqlite.
// 
// -----------------------------------------------------------------------------
- (void) quickUpdate
{
	int bundleVersion = self.bundleVersion;
	if ([dataStore countLibraries] == 0 || bundleVersion > self.installedVersion)
	{
		[Debug log: @"LibraryProperties.plist - quick updating - using bundle properties file version [%d]", bundleVersion];
		
		NSString *path = [[NSBundle mainBundle] pathForResource: @"LibraryProperties" ofType: @"plist"];
		[self loadDefaultLibraries: path];
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject: [NSString stringWithFormat: @"%d", bundleVersion] forKey: @"LibraryPropertiesVersion"];
	}

#if !(TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
	[self loadCustomLibraries];
	[self loadGenericLibraries];
#endif
}

// -----------------------------------------------------------------------------
//
// Download a new library properties file and update the locally stored one.
//
// This means that we will have two LibraryProperties.plist files:
//		* The downloaded one
//		* The orignal one in the main bundle
//
// -----------------------------------------------------------------------------
- (void) update
{
	NSUserDefaults *defaults	= [NSUserDefaults standardUserDefaults];
	NSDate *lastUpdate			= [defaults objectForKey: @"LibraryPropertiesLastUpdate"];

	// Do a quick update to make sure we at least have the bundle's copy
	// of the libraries list installed
	[self quickUpdate];

	// See if we are due for another update check
	NSTimeInterval secondsSinceLastUpdate = -1 * [lastUpdate timeIntervalSinceNow];
	if (lastUpdate != nil && secondsSinceLastUpdate < CHECK_INTERVAL)
	{
		// We are not due for another check yet
		[Debug log: @"LibraryProperties.plist - no update required - not due for next check - [%0.0f s] to go",
			CHECK_INTERVAL - secondsSinceLastUpdate];
		return;
	}
	
	// See if we have an up to date version
	NSDictionary *result = [self checkForUpdate];
	if (result == nil)
	{
		return;
	}
	
	NSURL *url			= [result objectForKey: @"url"];
	NSString *version	= [result objectForKey: @"version"];

	[Debug log: @"LibraryProperties.plist - downloading update from [%@]", [url absoluteString]];

	// Download the file
	NSData *data	= [[NSData alloc] initWithContentsOfURL: url];
	NSString *path	= [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent: @"LibraryProperties.plist"];
	[data writeToFile: path atomically: YES];
	[data release];
	
	[self loadDefaultLibraries: path];

#if !(TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
	[self loadCustomLibraries];
	[self loadGenericLibraries];
#endif

	// The update is sucessful
	[defaults setObject: version	   forKey: @"LibraryPropertiesVersion"];
	[defaults setObject: [NSDate date] forKey: @"LibraryPropertiesLastUpdate"];
}

// -----------------------------------------------------------------------------
//
// Check to see if an update is available for download.
//
// -----------------------------------------------------------------------------
- (NSDictionary *) checkForUpdate
{
	NSDictionary *info			= [[NSBundle mainBundle] infoDictionary];
	NSString *version			= [info objectForKey: @"CFBundleVersion"];
	NSString *updateURLString	= [[info objectForKey: @"UpdateURL"] stringByReplacingOccurrencesOfString: @"VERSION" withString: version];
	NSURL *updateURL			= [NSURL URLWithString: updateURLString];
	NSDictionary *updateInfo	= [NSDictionary dictionaryWithContentsOfURL: updateURL];

	if (updateInfo == nil)
	{
		[Debug log: @"LibraryProperties.plist - update check - failed to download [%@]", [updateURL absoluteURL]];
		return nil;
	}
	
	NSString *newVersionString	= [updateInfo objectForKey: @"LibraryPropertiesVersion"];
	int newVersion				= [newVersionString intValue];

	if (self.installedVersion >= newVersion)
	{
		// The version hasn't change so no update is needed
		[Debug log: @"LibraryProperties.plist - update check - no update required - version [%d] up to date", self.installedVersion];
		return nil;
	}
	
	[Debug log: @"LibraryProperties.plist - update check - update available for version [%d] to [%d]", self.installedVersion, newVersion];
	
	// Return the URL for the new properties file
	NSURL *url = [NSURL URLWithString: [updateInfo objectForKey: @"LibraryPropertiesURL"]];
	NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
		url,				@"url",
		newVersionString,	@"version",
		nil
	];
	return result;
}

// -----------------------------------------------------------------------------
//
// The version number for the properties file in the bundle.
// 
// -----------------------------------------------------------------------------
- (int) bundleVersion
{
	NSString *path				= [[NSBundle mainBundle] pathForResource: @"LibraryPropertiesVersion" ofType: @"plist"];
	NSDictionary *versionInfo	= [NSDictionary dictionaryWithContentsOfFile: path];
	NSString *bundleVersion		= [versionInfo objectForKey: @"LibraryPropertiesVersion"];
	
	return [bundleVersion intValue];
}

// -----------------------------------------------------------------------------
//
// The version number for the currently installed/active properties file.
// 
// -----------------------------------------------------------------------------
- (int) installedVersion
{
	NSUserDefaults *defaults	= [NSUserDefaults standardUserDefaults];
	NSString *currentVersion	= [defaults objectForKey: @"LibraryPropertiesVersion"];
	
	return (currentVersion == nil) ? 0 : [currentVersion intValue];
}

- (void) clearCache
{
	// Remove downloaded properties file
	NSString *path = [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent: @"LibraryProperties.plist"];
	[[NSFileManager defaultManager] removeItemAtPath: path error: nil];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults removeObjectForKey: @"LibraryPropertiesLastUpdate"];
	[defaults removeObjectForKey: @"LibraryPropertiesVersion"];
}

@end