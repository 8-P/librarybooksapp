#import "PreferencesWindowController.h"
#import "LibraryCard.h"
#import "OPAC.h"
#import "LibraryProperties.h"
#import "NSMenuExtension.h"
#import "LoginItems.h"
#import "NSAttributedStringExtension.h"
#import "SharedExtras.h"
#import "Calendar.h"
#import "NSPopUpButtonExtras.h"

#define FREE 1

@implementation PreferencesWindowController

@dynamic autoUpdate, autoUpdateInterval;
typedef enum {Upwards, Downwards} Direction;

+ (void) initialize
{
	// Setup application defaults
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults: [NSDictionary dictionaryWithObjectsAndKeys:
		// General preferences
		[NSNumber numberWithBool: YES],				@"SUCheckAtStartup",
		[NSNumber numberWithBool: YES],				@"AutoUpdate",
		[NSNumber numberWithInt:  1],				@"AutoUpdateInterval",
		[NSDate distantPast],						@"LastUpdateTime",
		[NSNumber numberWithBool: NO],				@"BookCovers",
		
		// Menu
		[NSNumber numberWithBool: YES],				@"ShowStatusBarText",
		[NSNumber numberWithInteger: 350],			@"MenuWidth",
		[NSNumber numberWithInteger: 10],			@"MenuItemLimit",
		
		// Alerts
		[NSNumber numberWithBool: NO],				@"ICalAlert",
		[NSNumber numberWithInteger: CalendarAlertMessageSound], @"ICalAlertType",
		[NSDate dateWithNaturalLanguageString: @"1 Jan 1970 09:00:00"], @"ICalAlertTime",
		[NSNumber numberWithBool: NO],				@"GrowlAlertOn",
		[NSNumber numberWithInteger: 2],			@"DueSoonWarningDays",
		
		// Status report
		[NSNumber numberWithBool: YES],				@"AllowStatusReport",
		[NSDate distantPast],						@"LastStatusReport",
		
		[NSNumber numberWithBool: YES],				@"FirstLaunch",
		
		nil]
	];
	
	// Force book cover updates to be off
	[userDefaults setBool: NO forKey: @"BookCovers"];
	
	if ([[[DataStore sharedDataStore] selectLibraryCards] count] > 0)
	{
		[userDefaults setBool: NO forKey: @"FirstLaunch"];
	}
}

- (IBAction) display: (id) sender
{
	// Dismiss the calling menu
//	NSMenu* menu = [[sender enclosingMenuItem] menu];
//	[menu cancelTracking];

	[[self window] center];
	[[self window] makeKeyAndOrderFront: nil];
	[NSApp activateIgnoringOtherApps: YES];

#if 0
	// Turn on core location to determine current location.  Note that we only
	// enable core-location when the preferences menu is displayed and not in
	// awakFromNib because we don't want the "Do you want to allow core location"
	// dialog to appear on app startup
	if (locationManager == nil)
	{
		locationManager						= [[CLLocationManager alloc] init];
		locationManager.desiredAccuracy		= kCLLocationAccuracyThreeKilometers;
		locationManager.distanceFilter		= 1000;
		locationManager.delegate			= self;
		
		if (locationManager.locationServicesEnabled)
		{
			[locationManager startUpdatingLocation];
		}
	}
#endif
	
	checkedForUpdate = NO;
	
	// Update the start a login checkbox
	[startAtLogin setState: ([LoginItems isLoginItemEnabled] == YES) ? NSOnState : NSOffState];
}

- (void) awakeFromNib
{
	[toolbar setAllowsUserCustomization: NO];
	[toolbar setAutosavesConfiguration: NO];
	
	[editLibraryCardTabView setTabViewType: NSNoTabsBezelBorder];
	
	// Set up delegates so we can enable/disable the "Save" button
	[authenticationDisplayName setDelegate: self];
	[authentication1Value setDelegate: self];
	[authentication2Value setDelegate: self];
	[authentication3Value setDelegate: self];
	[catalogueURL setDelegate: self];

	// Set up delegate for window close event
	[self.window setDelegate: self];
	
	[self restoreViewHeight: libraryCardsView withItemIdentifier: @"libraryCards"];
	[self showLibraryCardsView: nil];
	[[[self window] standardWindowButton: NSWindowZoomButton] setEnabled: NO];
	
	// Double clicking a row will edit it
	[libraryCardsTableView setDoubleAction: @selector(editLibraryCard:)];
	
	// Allow re-ordering
	[libraryCardsTableView setDraggingSourceOperationMask: NSDragOperationMove forLocal: YES];
	[libraryCardsTableView registerForDraggedTypes: [NSArray arrayWithObject: @"MoveRow"]];
	[libraryCardsTableView setDelegate: self];
	[libraryCardsTableView setDataSource: self];
	
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: @"ordering"
		ascending: YES selector: @selector(compare:)];
	[libraryCardsArrayController setSortDescriptors: [NSArray arrayWithObject: sortDescriptor]];
	
	[editLibraryCardTabViewItemOPACClickHere retain];
	
#ifdef APP_STORE
	[toolbar removeItemAtIndex: 5];
#elif FREE
	[toolbar removeItemAtIndex: 5];
	[toolbar removeItemAtIndex: 5];
#else
	if ([[[DataStore sharedDataStore] selectLibraryCards] count] > 0)
	{
		[self showBuyView: nil];
	}
#endif
}

- (void) dealloc
{
	[opacIdentifier release];
	[currentLocation release];
	[locationManager release];
	
	[super dealloc];
}

- (IBAction) addLibraryCard: (id) sender
{
	[libraryCardsTableView deselectAll: nil];
	[self updateThenEditLibraryCard];
}

- (IBAction) editLibraryCard: (id) sender
{
	[self updateThenEditLibraryCard];
}

- (void) windowWillClose:(NSNotification *)notification
{
	[self postConfigurationChangedNotification: nil];
}

- (IBAction) postConfigurationChangedNotification:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName: @"ConfigurationChanged" object: nil];
}

// =============================================================================
#pragma mark -
#pragma mark Library cards table

- (BOOL) tableView: (NSTableView *) tableView writeRows: (NSArray *) rows toPasteboard: (NSPasteboard *) pboard
{
	if ([rows count] == 0) return NO;
	
	// Declare our own pasteboard types
	[pboard declareTypes: [NSArray arrayWithObject: @"MoveRow"] owner: nil];

    // Add the data for the row
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject: rows];
    [pboard setData: data forType: @"MoveRow"];
	
    return YES;
}

- (NSDragOperation) tableView: (NSTableView *) tableView validateDrop: (id <NSDraggingInfo>) info
	proposedRow: (NSInteger) row proposedDropOperation: (NSTableViewDropOperation) operation
{
	// Make sure we drop the item between and not on top of the other items
	[tableView setDropRow: row dropOperation: NSTableViewDropAbove];
    return NSDragOperationMove;
}

- (BOOL) tableView: (NSTableView *) tableView acceptDrop: (id <NSDraggingInfo>) info
	row: (NSInteger) row dropOperation: (NSTableViewDropOperation) operation
{
	NSArray* rows = [NSKeyedUnarchiver unarchiveObjectWithData: [[info draggingPasteboard] dataForType: @"MoveRow"]];
	int oldRow = [[rows objectAtIndex: 0] intValue];

	// Ignore request that don't reorganise the list
	if (oldRow == row || oldRow + 1 == row) return NO;
	
	// Reorganise the data, now then when shifting down the new row index is off
	// by one so we need to fix it up
	if (oldRow < row) row--;
	
	Direction direction = (oldRow < row) ? Downwards : Upwards;
	int ordering		= 0;

	DataStore *dataStore = [DataStore sharedDataStore];
	for (LibraryCard *libraryCard in [dataStore selectAllLibraryCards])
	{
		if (ordering == oldRow)
		{
			libraryCard.ordering = [NSNumber numberWithInt: row];
		}
		else
		{
			if (direction == Downwards)
			{
				// The row is being move downwards so shift the other rows up
				if (oldRow < ordering && ordering <= row)
				{
					libraryCard.ordering =  [NSNumber numberWithInt: ordering - 1];
				}
			}
			else
			{
				// The row is being move upwards so shift the other rows down
				if (row <= ordering && ordering < oldRow)
				{
					libraryCard.ordering =  [NSNumber numberWithInt: ordering + 1];
				}
			}
		}
		
		ordering++;
	}
	
	// Debug
	NSLog(@"Re-ordered library cards:");
	for (LibraryCard *libraryCard in [dataStore selectAllLibraryCards])
	{
		NSLog(@"\t%d - %@", [libraryCard.ordering intValue], libraryCard.name);
	}
	
	[dataStore save];
	
	[tableView reloadData];
	[libraryCardsArrayController rearrangeObjects];
	
	return YES;
}

// =============================================================================
#pragma mark -
#pragma mark Update before add/edit library card

- (void) updateThenEditLibraryCard
{
	if (checkedForUpdate == NO)
	{
		// Display the update sheet
		[NSApp beginSheet:	updateWindow
			modalForWindow:	[self window]
			modalDelegate:	nil
			didEndSelector:	nil
			contextInfo:	nil
		];
		
		// Start the update thread
		updateOperation = [[NSInvocationOperation alloc] initWithTarget: self 
			selector: @selector(updateLibrariesListThread) object: nil];
		NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
		[operationQueue addOperation: updateOperation];
		[updateOperation release];
		[operationQueue release];
	}
	else
	{
		[self displayEditLibraryCard];
	}
}

- (IBAction) cancelUpdate: (id) sender
{
	[updateOperation cancel];
	[self displayEditLibraryCard];
}

// -----------------------------------------------------------------------------
//
// Wrapper for the LibraryProperties' checkForUpdate to display the
// network activity indicator when the check is happening.
//
// -----------------------------------------------------------------------------
- (BOOL) checkForUpdate
{
	LibraryProperties *libraryProperties = [LibraryProperties libraryProperties];
	NSDictionary *updateInfo = [libraryProperties checkForUpdate];
	return updateInfo != nil;
}

// -----------------------------------------------------------------------------
//
// NSInvocationOperation thread for doing the updating.
//
// -----------------------------------------------------------------------------
- (void) updateLibrariesListThread
{
	[updateProgressIndicator startAnimation: nil];
	
	[[LibraryProperties libraryProperties] quickUpdate];
	if ([self checkForUpdate])
	{
		LibraryProperties *libraryProperties = [LibraryProperties libraryProperties];
		[libraryProperties clearCache];
		[libraryProperties update];
	}
	
	checkedForUpdate = YES;
	[NSThread sleepForTimeInterval: 1];
	
	// Only display the edit panel if the the cancel button hasn't been pressed
	if ([updateOperation isCancelled] == NO)
	{
		[self performSelectorOnMainThread: @selector(displayEditLibraryCard)
			withObject: nil waitUntilDone: NO];
	}
}

// =============================================================================
#pragma mark -
#pragma mark Add/edit library card

// -----------------------------------------------------------------------------
//
// Display the edit library card sheet.  There are two modes of operation:
//		* Adding a new library card
//		* Editing an existing library card
//
// -----------------------------------------------------------------------------
- (void) displayEditLibraryCard
{
//	[[LibraryProperties libraryProperties] quickUpdate];
	
	// Hide update window
	[NSApp endSheet: updateWindow];
	[updateWindow orderOut: self];

	[self updateLibrariesMenu];
	[self updateDateFormatsMenu];
	[self updateGenericCatalogueSettings];
	
	NSInteger row = [libraryCardsTableView selectedRow];
	if (row >= 0)
	{
		LibraryCard *libraryCard = [[libraryCardsArrayController arrangedObjects] objectAtIndex: row];
		OPAC *opac = [OPAC opacForLibraryCard: libraryCard];
	
		// Handle deleted libraries
		if (opac == nil)
		{
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert setMessageText:		@"Library Not Supported"];
			[alert setInformativeText:	@"Library Books no longer supports your library.  Your library may have changed to a catalogue system that Library Books does not support."];
			[alert addButtonWithTitle:	@"Delete Library Card"];
			[alert addButtonWithTitle:	@"Cancel"];
			
			if ([alert runModal] == NSAlertFirstButtonReturn)
			{
				[[DataStore sharedDataStore] deleteLibraryCard: libraryCard];
			}
			
			return;
		}
	
		[opacIdentifier release];
		opacIdentifier = [libraryCard.libraryPropertyName retain];
		
		[librariesPopUpButton setTitle: opac.name];
		[authenticationDisplayName setStringValue: libraryCard.name];

		if ((opac.authenticationCount) >= 1) authentication1Value.text = libraryCard.authentication1;
		if ((opac.authenticationCount) >= 2) authentication2Value.text = libraryCard.authentication2;
		if ((opac.authenticationCount) >= 3) authentication3Value.text = libraryCard.authentication3;
		
		[catalogueURL setStringValue: [opac.catalogueURL absoluteString]];
		
		[dateFormatButton selectItemWithRepresentedObject: opac.dateFormat];
	}
	else
	{
		[opacIdentifier release];
		opacIdentifier = nil;
		
		[librariesPopUpButton setTitle: @"Select Library"];
		[authenticationDisplayName setStringValue: @""];
		
		authentication1Value.text = @"";
		authentication2Value.text = @"";
		authentication3Value.text = @"";
		
		[catalogueURL setStringValue: @""];
	}
	
	[self redrawTabs];
	[self redrawAuthentication];

	// Display the sheet
	[NSApp beginSheet:	editLibraryCardWindow
		modalForWindow:	[self window]
		modalDelegate:	nil
		didEndSelector:	nil
		contextInfo:	nil
	];
}

- (void) redrawAuthentication
{
	if (opacIdentifier == nil)
	{
		// Handle the case when no library has been selected
		
		[authentication1Title setHidden: YES];
		[authentication1Value setHidden: YES];

		[authentication2Title setHidden: YES];
		[authentication2Value setHidden: YES];
		
		[authentication3Title setHidden: YES];
		[authentication3Value setHidden: YES];
		
		[noteTextField setStringValue: @""];
	}
	else
	{
		NSMutableDictionary *properties = [[LibraryProperties libraryProperties]
			libraryPropertiesForIdentifier: opacIdentifier];
		OPAC <OPAC> *opac = [OPAC opacForProperties: properties];

		NSRect lastAuthenticationValueFrame = [authentication1Value frame];
		
		if ((opac.authenticationCount) >= 1)
		{
			[authentication1Title setStringValue:	[opac.authentication1Title stringByAppendingString: @":"]];
			authentication1Value.secureTextEntry	= opac.authentication1IsSecure;
			authentication1Value.placeholder		= (opac.authentication1Required) ? @"Required" : @"";
			lastAuthenticationValueFrame			= [authentication1Value frame];
		}
		
		if ((opac.authenticationCount) >= 2)
		{
			[authentication2Title setStringValue:	[opac.authentication2Title stringByAppendingString: @":"]];
			authentication2Value.secureTextEntry	= opac.authentication2IsSecure;
			authentication2Value.placeholder		= (opac.authentication2Required) ? @"Required" : @"";
			lastAuthenticationValueFrame			= [authentication2Value frame];
		}
		
		if ((opac.authenticationCount) >= 3)
		{
			[authentication3Title setStringValue:	[opac.authentication3Title stringByAppendingString: @":"]];
			authentication3Value.secureTextEntry	= opac.authentication3IsSecure;
			authentication3Value.placeholder		= (opac.authentication3Required) ? @"Required" : @"";
			lastAuthenticationValueFrame			= [authentication3Value frame];
		}
		
		// Hide unneeded authentication
		[authentication1Title setHidden: (opac.authenticationCount) < 1];
		[authentication1Value setHidden: (opac.authenticationCount) < 1];

		[authentication2Title setHidden: (opac.authenticationCount) < 2];
		[authentication2Value setHidden: (opac.authenticationCount) < 2];
		
		[authentication3Title setHidden: (opac.authenticationCount) < 3];
		[authentication3Value setHidden: (opac.authenticationCount) < 3];
		
		// Set the note text
		NSString *noteString = [properties objectForKey: @"Note"];
		[noteTextField setStringValue: (noteString) ? noteString : @""];
		
		// Position the note just under the last authentication input box
		NSRect rect		= [noteTextField frame];
		rect.origin.y	= lastAuthenticationValueFrame.origin.y - rect.size.height - 10;
		[noteTextField setFrame: rect];
	}
	
	[self updateSaveEnabled];
}

// -----------------------------------------------------------------------------
//
// Set the correct tab configuration.
//
// -----------------------------------------------------------------------------
- (void) redrawTabs
{
	if ([editLibraryCardTabView indexOfTabViewItem: editLibraryCardTabViewItemOPACClickHere] == NSNotFound)
	{
		[editLibraryCardTabView addTabViewItem: editLibraryCardTabViewItemOPACClickHere];
	}

	if (opacIdentifier == nil)
	{
		[editLibraryCardTabView setTabViewType: NSNoTabsBezelBorder];
		[editLibraryCardTabView selectTabViewItem: editLibraryCardTabViewItemOPACClickHere];
	}
	else if ([opacIdentifier hasPrefix: @"generic."])
	{
		if ([editLibraryCardTabView indexOfTabViewItem: editLibraryCardTabViewItemOPACClickHere] != NSNotFound)
		{
			[editLibraryCardTabView removeTabViewItem: editLibraryCardTabViewItemOPACClickHere];
		}

		[editLibraryCardTabView setTabViewType:		NSTopTabsBezelBorder];
		[editLibraryCardTabView selectTabViewItem:	editLibraryCardTabViewItemLibraryCard];
	}
	else
	{
		[editLibraryCardTabView setTabViewType:		NSNoTabsBezelBorder];
		[editLibraryCardTabView selectTabViewItem:	editLibraryCardTabViewItemLibraryCard];
	}
}

// -----------------------------------------------------------------------------
//
// This delegate is called when the location is detected.  We update the library
// drop down menu.
//
// -----------------------------------------------------------------------------
- (void) locationManager: (CLLocationManager *) manager didUpdateToLocation: (CLLocation *) newLocation fromLocation: (CLLocation *) oldLocation
{
	// We only want to grab the location once
	[locationManager stopUpdatingLocation];

	[currentLocation release];
	currentLocation = [newLocation retain];
	
	[self updateLibrariesMenu];
}

- (void) locationManager: (CLLocationManager *) manager didFailWithError: (NSError *) error
{
	// Do nothing on error
}

// -----------------------------------------------------------------------------
//
// Build the OPAC list.
//
// -----------------------------------------------------------------------------
- (void) updateLibrariesMenu
{
	NSMenu *menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems: NO];
	DataStore *dataStore = [DataStore sharedDataStore];
	
	// This the default menu item if nothing is selected
	[menu addItemWithTitle: @""];
	
	// Favourite libraries i.e. a list of libraries already in use, e.g. used
	// by other family members
	NSArray *librariesInUse = [dataStore selectLibrariesInUse];
	if ([librariesInUse count] > 0)
	{
		[[menu addItemWithTitle: @"Favourite Libraries:"] setEnabled: NO];
		
		for (Library *library in librariesInUse)
		{
			NSMenuItem *menuItem = [menu addItemWithTitle: library.name action: @selector(librarySelected:)];
			[menuItem setTarget: self];
			[menuItem setRepresentedObject: library.identifier];
			[menuItem setIndentationLevel: 1];
		}
		
		[menu addItem: [NSMenuItem separatorItem]];  // ------------------------
	}
	
	NSArray *nearbyLocations = [dataStore locationsNearLocation: currentLocation];
	if ([nearbyLocations count] > 0)
	{
		[[menu addItemWithTitle: @"Nearby Libraries:"] setEnabled: NO];

		for (Location *location in nearbyLocations)
		{
			Library *library = [dataStore selectLibraryForIdentifier: location.identifier];
		
			NSMenuItem *menuItem = [menu addItemWithTitle: library.name action: @selector(librarySelected:)];
			[menuItem setTarget: self];
			[menuItem setRepresentedObject: library.identifier];
			[menuItem setIndentationLevel: 1];
		}
		
		[menu addItem: [NSMenuItem separatorItem]];  // ------------------------
	}
	
	[[menu addItemWithTitle: @"All Libraries:"] setEnabled: NO];
	[self appendMenuItemsTo: menu forPath: @"/" indentationLevel: 1 type: @"default"];
	
	[menu addItem: [NSMenuItem separatorItem]];  // ----------------------------
	
	if ([dataStore countLibrariesWithType: @"custom"] > 0)
	{
		[[menu addItemWithTitle: @"User Libraries:"] setEnabled: NO];
		[self appendMenuItemsTo: menu forPath: @"/" indentationLevel: 1 type: @"custom"];
		
		[menu addItem: [NSMenuItem separatorItem]];  // ------------------------
	}
		
	NSMenuItem *menuItem = [menu addItemWithTitle: @"Generic Libraries"];
	NSMenu *submenu	= [[NSMenu alloc] init];
	[menuItem setSubmenu: submenu];
	[self appendMenuItemsTo: submenu forPath: @"/" indentationLevel: 1 type: @"generic"];
	[submenu release];
	
	[librariesPopUpButton setMenu: menu];
	[menu release];
}

- (void) appendMenuItemsTo: (NSMenu *) menu forPath: (NSString *) path indentationLevel: (NSUInteger) indentationLevel
	type: (NSString *) type
{
	DataStore *dataStore	= [DataStore sharedDataStore];
	NSArray *items			= [dataStore libraryDrillDownItemForPath: path type: type];
	
	for (LibraryDrillDownItem *item in items)
	{
		NSMenuItem *menuItem;
		if ([item.isFolder boolValue])
		{
			// Recursion
			menuItem		= [menu addItemWithTitle: item.name];
			NSMenu *submenu	= [[NSMenu alloc] init];
			
			[self appendMenuItemsTo: submenu forPath: [item.path stringByAppendingPathComponent: item.name]
				indentationLevel: 0 type: type];
			[menuItem setSubmenu: submenu];
			[submenu release];
		}
		else
		{
			menuItem = [menu addItemWithTitle: item.name action: @selector(librarySelected:)];
			[menuItem setTarget: self];
			[menuItem setRepresentedObject: item.library.identifier];
			
			if (item.imageName)
			{
				[menuItem setImage: [NSImage imageNamed: item.imageName]];
			}
			
			if (item.name2)
			{
				NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString: @""];
				[title appendAttributedString: [NSAttributedString normalPopUpMenuString: item.name]];
				[title appendAttributedString: [NSAttributedString normalMenuString: @"\n"]];
				[title appendAttributedString: [NSAttributedString smallMenuString: item.name2]];
				
				[menuItem setAttributedTitle: title];
				[title release];
			}
		}
		
		[menuItem setIndentationLevel: indentationLevel];
	}
}

// -----------------------------------------------------------------------------
//
// Setup the date formats menu.
//
// -----------------------------------------------------------------------------
- (void) updateDateFormatsMenu
{
	NSMenu *menu = [[NSMenu alloc] init];
	[menu setAutoenablesItems: NO];
	
	const int dateFormatsCount = 5;
	NSString *dateFormats[][3] =
	{
		{ @"Month Day Year",	@"month day year",	@"Example: 01-26-09, Jan 26 2009, etc"	},
		{ @"-",					@"-",				@"-"									},
		{ @"Day Month Year",	@"day month year",	@"Example: 26/01/09, 26 Jan 2009, etc"	},
		{ @"-",					@"-",				@"-"									},
		{ @"Year Month Day",	@"year month day",	@"Example: 09-01-26, 2009-01-26, etc"	},
	};
	
	for (int i = 0; i < dateFormatsCount; i++)
	{
		NSString *name		= dateFormats[i][0];
		NSString *format	= dateFormats[i][1];
		NSString *example	= dateFormats[i][2];
		
		if ([name isEqualToString: @"-"])
		{
			[menu addItem: [NSMenuItem separatorItem]];
		}
		else
		{
			NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString: @""];
			[title appendAttributedString: [NSAttributedString normalPopUpMenuString: name]];
			[title appendAttributedString: [NSAttributedString normalPopUpMenuString: @"\n"]];
			[title appendAttributedString: [NSAttributedString smallMenuString: example]];
			
			NSMenuItem *menuItem = [menu addItemWithAttributedString: title];
			[menuItem setRepresentedObject: format];

			[title release];
		}
	}
	
	[dateFormatButton setMenu: menu];
	[menu release];
}

// -----------------------------------------------------------------------------
//
// This selector is called when a OPAC is selected in the OPAC drop down list.
//
// -----------------------------------------------------------------------------
- (void) librarySelected: (id) sender
{
	NSString *oldIdentifier = [opacIdentifier copy];
	NSString *newIdentifier = [sender representedObject];
	NSString *newTitle		= [[sender title] stringUptoFirst: @"\n"];
	
	// Update the display name
	[self updateDisplayNameFromIdentifer: oldIdentifier toIdentifier: newIdentifier];
	[oldIdentifier release];

	// Update the drop down title to represent the new selection
	[librariesPopUpButton setTitle: newTitle];
	
	// Remember the opac identifier
	[opacIdentifier release];
	opacIdentifier = [newIdentifier retain];
	
	[self redrawTabs];
	[self redrawAuthentication];
	[self updateGenericCatalogueSettings];
}

// -----------------------------------------------------------------------------
//
// Auto fill in the display name or rename it.  Examples:
//
//		""						-> "Darebin Library"
//		"Latrobe Library Blah"	-> "Darebin Library Blah"
//
// -----------------------------------------------------------------------------
- (void) updateDisplayNameFromIdentifer: (NSString *) oldIdentifier toIdentifier: (NSString *) newIdentifier
{
	OPAC *oldOPAC = [OPAC opacForIdentifier: oldIdentifier];
	OPAC *newOPAC = [OPAC opacForIdentifier: newIdentifier];
			
	if ([[authenticationDisplayName stringValue] length] == 0)
	{
		[authenticationDisplayName setStringValue: newOPAC.name];
	}
	else if (oldOPAC)
	{
		NSMutableString *displayName = [[authenticationDisplayName stringValue] mutableCopy];
		[displayName replaceOccurrencesOfString: oldOPAC.name withString: newOPAC.name];
		[authenticationDisplayName setStringValue: displayName];
		[displayName release];
	}
}

- (NSArray *) nearbyLibraries
{
	DataStore *dataStore = [DataStore sharedDataStore];

	NSMutableArray *libraries = [[dataStore selectLibrariesInUse] mutableCopy];
	for (Location *location in [dataStore locationsNearLocation: currentLocation])
	{
		[libraries addObject: [dataStore selectLibraryForIdentifier: location.identifier]];
	}
	
	return [libraries autorelease];
}

- (IBAction) closeEditLibraryCard: (id) sender
{
	[NSApp endSheet: editLibraryCardWindow];
	[editLibraryCardWindow orderOut: self];
}

- (void) controlTextDidChange: (NSNotification *) notification
{
	[self updateSaveEnabled];
}

- (void) controlTextDidEndEditing: (NSNotification *) notification
{
	[self updateSaveEnabled];
}

- (void) updateSaveEnabled
{
	OPAC <OPAC> *opac = nil;
	if (opacIdentifier)
	{
		NSMutableDictionary *properties = [[LibraryProperties libraryProperties]
			libraryPropertiesForIdentifier: opacIdentifier];
		opac = [OPAC opacForProperties: properties];
	}

	BOOL enabled =
		   opac
		&& [[authenticationDisplayName stringValue] length] > 0
		&& ((1 <= opac.authenticationCount && opac.authentication1Required) ? [authentication1Value.text length] > 0 : YES)
		&& ((2 <= opac.authenticationCount && opac.authentication2Required) ? [authentication2Value.text length] > 0 : YES)
		&& ((3 <= opac.authenticationCount && opac.authentication3Required) ? [authentication3Value.text length] > 0 : YES);
	
	// Make sure the extra catalogue URL and date format are set
	if ([opacIdentifier hasPrefix: @"generic."])
	{
		enabled &= [[catalogueURL stringValue] length] > 0;
	}
	
	[saveButton setEnabled: enabled];
}

- (void) updateGenericCatalogueSettings
{
	if (opacIdentifier)
	{
		NSMutableDictionary *properties = [[LibraryProperties libraryProperties]
			libraryPropertiesForIdentifier: opacIdentifier];
		
		// Update the catalogue URL example
		NSString *catalogueURLExample = [properties objectForKey: @"CatalogueURLExample"];
		[catalogueURLExampleTextField setStringValue:
			(catalogueURLExample) ? [NSString stringWithFormat: @"Example: %@", catalogueURLExample] : @""];
			
		// Update the date format
		NSString *dateFormat = [properties objectForKey: @"DateFormat"];
		[dateFormatButton selectItemWithRepresentedObject: dateFormat];
	}
}

- (IBAction) saveEditLibraryCard: (id) sender
{
//	[[DataStore sharedDataStore] lock];

	LibraryCard *libraryCard;
	NSInteger row = [libraryCardsTableView selectedRow];
	if (row >= 0)
	{
		libraryCard = [[libraryCardsArrayController arrangedObjects] objectAtIndex: row];
	}
	else
	{
		libraryCard = [LibraryCard libraryCard];
		libraryCard.ordering = [NSNumber numberWithInt: [[DataStore sharedDataStore] maxLibraryCardOrdering] + 1];
	}

	if (opacIdentifier)
	{
		libraryCard.libraryPropertyName = opacIdentifier;
	}

	libraryCard.name				= [authenticationDisplayName stringValue];
	libraryCard.authentication1		= authentication1Value.text;
	libraryCard.authentication2		= authentication2Value.text;
	libraryCard.authentication3		= authentication3Value.text;
	
	// Save the override properties
	if ([opacIdentifier hasPrefix: @"generic."])
	{
		NSDictionary *overrideProperties = [NSDictionary dictionaryWithObjectsAndKeys:
			[catalogueURL stringValue],								@"CatalogueURL",
			[[dateFormatButton selectedItem] representedObject],	@"DateFormat",
			nil
		];
		
		libraryCard.overrideProperties = [NSKeyedArchiver archivedDataWithRootObject: overrideProperties];
	}
	
	[[DataStore sharedDataStore] save];

	[self closeEditLibraryCard: nil];
	[libraryCardsArrayController rearrangeObjects];
	
//	[[DataStore sharedDataStore] unlock];
}

- (BOOL) windowShouldClose: (id) sender
{
	[[DataStore sharedDataStore] save];
	return YES;
}

// =============================================================================
#pragma mark -
#pragma mark General Tab

// Determine if this app should start when the user logs in
- (IBAction) startAtLogin: (id) sender
{
//	if ([sender state] == NSOnState)	{ [LoginItems enableLoginItem: YES]; }
//	else								{ [LoginItems enableLoginItem: NO]; }
	
	BOOL success = [LoginItems enableLoginItem: [sender state] == NSOnState];
	if (success == NO)
	{
		// Restore the check box state if we can't enable the login item
		NSBeep();
		[sender setState: NSOffState];
	}
}

// =============================================================================
#pragma mark -
#pragma mark Advanced Tab

// =============================================================================
#pragma mark -
#pragma mark iPhone Tab

- (IBAction) openIOSAppStore: (id) sender
{
	[[URL URLWithString: @"http://itunes.apple.com/app/library-books/id365824503?mt=8"] openInWebBrowser];
}

// =============================================================================
#pragma mark -
#pragma mark Buy Tab

- (IBAction) openMacAppStore: (id) sender
{
	[[URL URLWithString: @"http://itunes.apple.com/app/library-books/id412822911?mt=12"] openInWebBrowser];
}

// =============================================================================
#pragma mark -
#pragma mark Tab actions

- (IBAction) showLibraryCardsView: (id) sender
{
	[[self window] setTitle: @"Library Cards"];
	[self setPreferencesView: libraryCardsView resizable: YES];
	[toolbar setSelectedItemIdentifier: @"libraryCards"];
}

- (IBAction) showLibraryGeneralView: (id) sender
{
	[[self window] setTitle: @"General"];
	[self setPreferencesView: generalView resizable: NO];
	[toolbar setSelectedItemIdentifier: @"general"];
}

- (IBAction) showLibraryMenuView: (id) sender
{
	[[self window] setTitle: @"Menu"];
	[self setPreferencesView: menuView resizable: NO];
	[toolbar setSelectedItemIdentifier: @"menu"];
}

- (IBAction) showAlertsView: (id) sender
{
	[[self window] setTitle: @"Alerts"];
	[self setPreferencesView: alertsView resizable: NO];
	[toolbar setSelectedItemIdentifier: @"alerts"];
}

- (IBAction) showLibraryAdvancedView: (id) sender
{
	[[self window] setTitle: @"Advanced"];
	[self setPreferencesView: advancedView resizable: NO];
	[toolbar setSelectedItemIdentifier: @"advanced"];
}

- (IBAction) showiPhoneView: (id) sender
{
	[[self window] setTitle: @"iPhone"];
	[self setPreferencesView: iPhoneView resizable: NO];
	[toolbar setSelectedItemIdentifier: @"iphone"];
}

- (IBAction) showBuyView: (id) sender
{
	[[self window] setTitle: @"Mac"];
	[self setPreferencesView: donateView resizable: NO];
	[toolbar setSelectedItemIdentifier: @"buy"];
}

- (void) setPreferencesView: (NSView*) view resizable: (BOOL) resizeable
{
	// Figure out the size of the new window
	float toolbarSize	 = [[self window] frame].size.height - [[[self window] contentView] frame].size.height;
	NSRect frame		 = [[self window] frame];
	NSSize frameSize	 = [view frame].size;
	frame.origin.y		+= frame.size.height - frameSize.height - toolbarSize;
	frame.size			 = frameSize;
	frame.size.height	+= toolbarSize;

	// Animate the transition by displaying a blank view firstly.  Then resize
	// the window and display the new view
	[[self window] setContentView: [[[NSView alloc] init] autorelease]];
	[[self window] setFrame: frame display: YES animate: YES];
	[[self window] setContentView: view];
	
	[[self window] setShowsResizeIndicator: resizeable];
}

// -----------------------------------------------------------------------------
//
// Handle window resizing.
//
//		* Set minimum height.
//		* Only allow resizing of the library cards view.
//		* Note that the prefrences window is resizable but we hide the handles
//		  and stop the resizing of the fixed views here.
//
// -----------------------------------------------------------------------------
- (NSSize) windowWillResize: (NSWindow *) sender toSize: (NSSize) proposedFrameSize
{
	if ([[self window] showsResizeIndicator])
	{
		// Make sure we can't change the width
		NSSize frameSize = proposedFrameSize;
		frameSize.width = [sender frame].size.width;
	
		// Maintain a minimum height
		frameSize.height = MAX(frameSize.height, 300);
	
		// Save the height to the user defaults
		float toolbarSize = [[self window] frame].size.height - [[[self window] contentView] frame].size.height;
		float height = frameSize.height - toolbarSize;
		
		NSString *key = [NSString stringWithFormat: @"PreferencesViewHeightFor%@", [toolbar selectedItemIdentifier]];
		[[userDefaultsController values] setValue: [NSNumber numberWithFloat: height] forKey: key];
	
		return frameSize;
	}
	else
	{
		return [sender frame].size;
	}
}

// -----------------------------------------------------------------------------
//
// Restore the height of a view.
//
//		* Called at start up to restore the view sizes.
//
// -----------------------------------------------------------------------------
- (void) restoreViewHeight: (NSView *) view withItemIdentifier: (NSString *) identifier
{
	NSString *key = [NSString stringWithFormat: @"PreferencesViewHeightFor%@", identifier];
	NSNumber *heightNumber = [[userDefaultsController values] valueForKey: key];
	
	if (heightNumber != nil)
	{
		// Restore the height
		NSRect frame		= [view frame];
		frame.size.height	= [heightNumber floatValue];
		[view setFrame: frame];
	}
}

// =============================================================================
#pragma mark -
#pragma mark Accessor functions

- (BOOL) autoUpdate
{
	return [[[userDefaultsController values] valueForKey: @"AutoUpdate"] boolValue];
}

- (NSTimeInterval) autoUpdateInterval
{
	int interval = [[[userDefaultsController values] valueForKey: @"AutoUpdateInterval"] intValue];
	
	// Map the preferences interval value to the correct number of seconds
	switch (interval)
	{
		case 0:		return        1 * 3600;
		case 13:	return       23 * 3600;
		default:	return interval * 3600;
	}
}

- (NSDate *) lastUpdateTime
{
	return [[userDefaultsController values] valueForKey: @"LastUpdateTime"];
}

- (void) setLastUpdateTime: (NSDate *) lastUpdateTime
{
	[[userDefaultsController values] setValue: lastUpdateTime forKey: @"LastUpdateTime"];
}

@end