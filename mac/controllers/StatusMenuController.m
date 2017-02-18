// =============================================================================
//
// This is the menubar menu.
//
// =============================================================================

#import "StatusMenuController.h"
#import "NSMenuExtension.h"
#import "LoansView.h"
#import "HoldsView.h"
#import "SectionView.h"
#import "NSAttributedStringExtension.h"
#import "OPAC.h"
#import "LibraryProperties.h"
#import "NSImageExtras.h"
#import "SharedExtras.h"
#import "Reachability.h"
#import "Calendar.h"
#import "Growl.h"
#import "StatusReporter.h"
#import "NSMenuItemExtras.h"
#import "Preferences.h"
#import "Spotlight.h"
#import "UpdatingView.h"
#import "MenuIconView.h"
#import "GettingStartedView.h"

#define FREE 1

@implementation StatusMenuController

- (void) awakeFromNib
{
	defaults = [[NSUserDefaults standardUserDefaults] retain];
	dataStore = [[DataStore sharedDataStore] retain];
	
	// Force a quick update to ensure the library list is updated
	[[LibraryProperties libraryProperties] quickUpdate];
	
	[self setupStatusItem];
	[self redrawStatusItem];
	[self redrawStatusMenu];
	[self setupTimer];
	[self setupTooltips];
	
	[self displaySpotlightForBeginners];
	
			
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(redraw)
		name: @"ConfigurationChanged" object: nil];
}

- (void) setupTooltips
{
	[tooltipLabel setStringValue: @""];

	NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingActiveInActiveApp;
	
	NSArray *buttons = [NSArray arrayWithObjects: quitButton, preferencesButton, aboutButton, debugButton, printButton, nil];
	for (NSButton *button in buttons)
	{
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject: button forKey: @"sender"];
		NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect: [button bounds]
			options: trackingOptions owner: self userInfo: userInfo];
		[button addTrackingArea: trackingArea];
		[trackingArea release];
	}
	
	// Make sure the tooltip text gets cleared when the menu disappears
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(menuClose:)
		name: NSMenuDidEndTrackingNotification object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(menuOpen:)
		name: NSMenuDidBeginTrackingNotification object: nil];
}

// Create the status item and load the default menu
- (void) setupStatusItem
{
	NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
	statusItem = [statusBar statusItemWithLength: NSVariableStatusItemLength];
	[statusItem retain];
	
	[statusItem setHighlightMode:  YES];
//	[statusItem setImage:          [NSImage imageNamed: @"MenuIconGreyNone.png"]];
//	[statusItem setAlternateImage: [NSImage imageNamed: @"MenuIconAltNone.png"]];

	statusItemView = [[MenuIconView menuIconView] retain];
	statusItemView.statusItem = statusItem;
//	statusItemView.bookmarkWindow = bookmarkWindow;
	[statusItem setView: statusItemView];
}

// -----------------------------------------------------------------------------
//
// Display a spotlight to highlight the position of the menu bar icon.
//
//		* Do this to help new user's find the application.
//		* This is equivalent of bouncing the app icon.
//		* Create a temporary status item to get the position of the icon.
//
// -----------------------------------------------------------------------------
- (void) displaySpotlightForBeginners
{
	if ([defaults boolForKey: @"FirstLaunch"] == NO) return;
	[defaults setBool: NO forKey: @"FirstLaunch"];

	NSStatusBar *statusBar = [NSStatusBar systemStatusBar];
	NSStatusItem *tempStatusItem = [statusBar statusItemWithLength: 1];
	[tempStatusItem setView: [[[NSView alloc] initWithFrame: NSZeroRect] autorelease]];
	
	NSRect frame = [[[tempStatusItem view] window] frame];
	NSPoint point = NSMakePoint(NSMidX(frame) + 10, NSMinY(frame));
	
	Spotlight *spotlight = [Spotlight sharedSpotlight];
	spotlight.view = spotlightMessageView;
	[spotlight displaySpotlightAt: point];
	
	[statusBar removeStatusItem: tempStatusItem];
}

- (void) redraw
{
	[self redrawStatusItem];
	[self redrawStatusMenu];
}

// -----------------------------------------------------------------------------
//
// Redraw the menu bar status item.  Things that may change:
//
//		* Text
//		* Icon colour
//
// -----------------------------------------------------------------------------
- (void) redrawStatusItem
{
//[statusItem setTitle: [NSString stringWithFormat: @" %d", [dataStore countLoans]]];
//return;

	// Set the title
	if ([defaults boolForKey: @"ShowStatusBarText"])
	{
//		[statusItem setTitle: [NSString stringWithFormat: @" %d", [dataStore countLoans]]];
		statusItemView.stringValue = [NSString stringWithFormat: @"%d", [dataStore countLoans]];
	}
	else
	{
//		[statusItem setTitle: @""];
		statusItemView.stringValue = @"";
	}
	
	// Pick and set the icon image
//	NSString *loans		= @"Grey";
//	NSString *holds		= @"None";
//	NSString *holdsAlt	= @"None";
	
	NSInteger dueSoonWarningSeconds = [Preferences sharedPreferences].dueSoonWarningDays * 86400;
	if ([dataStore countOverdueLoans] > 0)
	{
		statusItemView.bookColour = @"Red";
//		loans = @"Red";
	}
	else if ([dataStore countLoansDueBefore: [[NSDate today] dateByAddingTimeInterval: dueSoonWarningSeconds]] > 0)
	{
		statusItemView.bookColour = @"Orange";
//		loans = @"Orange";
	}
	else
	{
		statusItemView.bookColour = @"Black";
	}
	
	if ([dataStore countReadyForPickupHolds] > 0)
	{
//		holds		= @"Green";
//		holdsAlt	= @"Alt";
		
//		statusItemView.bookmarkColour = @"Green";
		statusItemView.bookmarkColour = @"Black";
		
		if ([statusItemView.bookColour isEqualToString: @"Black"])
		{
			statusItemView.bookColour = @"Green";
		}
	}
	else if ([dataStore countHolds] > 0)
	{
//		holds		= @"Grey";
//		holdsAlt	= @"Alt";
		
		statusItemView.bookmarkColour = @"Black";
		
		if ([statusItemView.bookColour isEqualToString: @"Black"])
		{
			statusItemView.bookmarkColour = @"White";
		}
	}
	else
	{
		statusItemView.bookmarkColour = @"";
	}
	
//	NSImage *image			= [NSImage imageNamed: [NSString stringWithFormat: @"MenuIcon%@%@.png", loans, holds]];
//	NSImage *alternateImage	= [NSImage imageNamed: [NSString stringWithFormat: @"MenuIconAlt%@.png", holdsAlt]];
	
//	[statusItem setImage: image];
//	[statusItem setAlternateImage: alternateImage];
}

// -----------------------------------------------------------------------------
//
// Draw the menu.
//
// -----------------------------------------------------------------------------
- (void) redrawStatusMenu
{
	// Make a new status menu but don't draw anything.  We will do the drawing on
	// demand in updateStatusMenu
	[statusMenu autorelease];
	statusMenu = [[NSMenu menu] retain];
	
	[statusItem setMenu: statusMenu];
	[statusMenu setDelegate: self];
		
	menuUpdateNeeded = YES;
}

- (void)menuDidClose:(NSMenu *)menu {
	[(MenuIconView *) statusItem.view highlight: NO];
}

- (void) menuWillOpen: (NSMenu *) menu
{
	MenuIconView *menuIconView = (MenuIconView *) statusItem.view;
	[menuIconView highlight: YES];

	if (menuIconView.compactDisplayMode == NO)
	{
		if (menuUpdateNeeded == NO)
		{
			[self refreshLastUpdated];
			return;
		}
		menuUpdateNeeded = NO;
	}

	[menu removeAllItems];

//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSInteger menuWidth = [defaults integerForKey: @"MenuWidth"];
	NSInteger menuItemLimit = [defaults integerForKey: @"MenuItemLimit"];
	
	if (menuIconView.compactDisplayMode)
	{
		menuItemLimit = 1000;
		menuUpdateNeeded = YES;
	}

	
/*	[[menu addItemWithTitle: @"Update" action: @selector(update:)]
		setTarget: self];
	NSAttributedString *title = [self lastUpdateTimeDescription];
	if (title != nil)
	{
		NSMenuItem *oldMenuItem = lastUpdateMenuItem;
		lastUpdateMenuItem = [[menu addItemWithAttributedString: title] retain];
		[oldMenuItem release];
	}*/
	
//	[menu addItem: [NSMenuItem separatorItem]];  // ---------------------
	
	NSArray *libraryCards = [dataStore selectLibraryCards];
	if ([libraryCards count] == 0)
	{
		// Display a "Click to add library card" hint if no libraries have been
		// configured
//		NSMenuItem *menuItem = [menu addItemWithTitle: @""];
//
//		NSImage *image		= [NSImage imageNamed: @"ClickToAddLibrary"];
//		NSSize imageSize	= [image size];
//		NSImageView *view	= [[NSImageView alloc] initWithFrame: NSMakeRect(0, 0, imageSize.width, imageSize.height)];
//		[view setImage: image];
//		[menuItem setView: view];
//
//		[view release];
		
		
		
		GettingStartedView *gettingStartedView = [[GettingStartedView alloc] init];
		[menu addItemWithView: gettingStartedView.view];
		
		[gettingStartedView release];
	}
	else
	{
		[_updateMenuItem release];
		_updateMenuItem = [[menu addItemWithTitle: @"" action: @selector(update:) target: self] retain];
		[_updateMenuItem setImage: [NSImage imageNamed: NSImageNameRefreshFreestandingTemplate]];
		if (updating)
		{
			UpdatingView *view = [UpdatingView updatingViewWithWidth: 400];
			[_updateMenuItem setView: view];
		}
		[self refreshLastUpdated];
	}
	
	[menu addSeparatorItem];
	
	// For detection of a working generic library
	BOOL workingGeneric = NO;
	
	for (LibraryCard *libraryCard in libraryCards)
	{
		NSMenuItem *cardNameItem = [menu addItemWithBoldTitle: libraryCard.name];
		NSMenu *libraryMenu = [NSMenu menu];
		[cardNameItem setSubmenu: libraryMenu];
		
		OPAC<OPAC> *opac = [OPAC opacForLibraryCard: libraryCard];
		OPAC<OPAC> *eBookOpac = [OPAC eBookOpacForLibraryCard: libraryCard];
		
		if ([opac myAccountEnabled])
		{
			[libraryMenu addItemWithTitle:	@"My Account"
				action:						@selector(openMyAccountPage:)
				target:						self
				representedObject:			libraryCard];
		}
		else
		{
			// The My Account link is not available for some libraries.  Display
			// a "Not Available" message so users don't complain about a broken
			// feature
			[libraryMenu addItemWithTitle:	@"My Account"];
			[libraryMenu addItemWithAttributedString: [NSAttributedString tinyDisabledMenuString: @"(NOT AVAILABLE FOR THIS LIBRARY)"]];
		}
		
		if ([eBookOpac myAccountEnabled])
		{
			[libraryMenu addItemWithTitle:	@"My eBook Account"
				action:						@selector(openMyEBookAccountPage:)
				target:						self
				representedObject:			libraryCard];
		}
		
		if ([opac respondsToSelector: @selector(renewItemsURL)])
		{
			[libraryMenu addItemWithTitle:	@"Renew Items"
				action:						@selector(openRenewItemsPage:)
				target:						self
				representedObject:			libraryCard];
		}
		
		[libraryMenu addItemWithTitle:	@"Library Web Page"
			action:						@selector(openLibraryWebPage:)
			target:						self
			representedObject:			libraryCard.libraryPropertyName];
		
		URL *openingHoursURL = opac.openingHoursURL;
		if (openingHoursURL)
		{
			[libraryMenu addItemWithTitle:	@"Opening Hours"
				action:						@selector(openURL:)
				target:						self
				representedObject:			openingHoursURL];
		}
		
//		[libraryMenu addItemWithTitle:	@"Google Book Search"
//			action:						@selector(openURL:)
//			target:						self
//			representedObject:			[URL URLWithString: @"http://books.google.com"]];

		// Copy to clipboard items
		if (opac.authenticationCount > 0)
		{
			[libraryMenu addItem: [NSMenuItem separatorItem]];
			if (opac.authenticationCount >= 1 && opac.authentication1IsSecure == NO)
			{
				[libraryMenu addItemWithTitle:	[NSString stringWithFormat: @"Copy %@ to Clipboard", opac.authentication1Title]
					action:						@selector(copyToClipboard:)
					target:						self
					representedObject:			libraryCard.authentication1];
			}
			if (opac.authenticationCount >= 2 && opac.authentication2IsSecure == NO)
			{
				[libraryMenu addItemWithTitle:	[NSString stringWithFormat: @"Copy %@ to Clipboard", opac.authentication2Title]
					action:						@selector(copyToClipboard:)
					target:						self
					representedObject:			libraryCard.authentication2];
			}
			if (opac.authenticationCount >= 3 && opac.authentication3IsSecure == NO)
			{
				[libraryMenu addItemWithTitle:	[NSString stringWithFormat: @"Copy %@ to Clipboard", opac.authentication3Title]
					action:						@selector(copyToClipboard:)
					target:						self
					representedObject:			libraryCard.authentication3];
			}
		}

		if (libraryCard.lastUpdated && fabs([libraryCard.lastUpdated timeIntervalSinceDate: preferences.lastUpdateTime]) >= 3600)
		{
			NSString *timeAgoString = [libraryCard.lastUpdated timeAgoString];
	
			NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] init] autorelease];
			[string appendAttributedString: [NSAttributedString tinyItalicDisabledMenuString:  @"last successful update  "]];
			[string appendAttributedString: [NSAttributedString tinyDisabledMenuString:  [timeAgoString uppercaseString]]];
		
			[menu addItemWithAttributedString: string];
		}
		
		[menu addItem: [NSMenuItem spacerItem]];

		if ([libraryCard.authenticationOK boolValue] == NO)
		{
			[menu addItem: [NSMenuItem sectionItemWithTitle: @"INVALID LOGIN"]];
		}
		
		__block BOOL spacerNeeded = NO;
		
		// Loans
		void (^addLoans)() = ^(NSArray *loans, NSString *name, NSString *namePlural)
		{
			// Add spacer to separate from previous item
			if (spacerNeeded) [menu addItem: [NSMenuItem spacerItem]];
		
			NSUInteger loansCount = [loans count];
			if (loansCount > 0)
			{
				[menu addItem: [NSMenuItem sectionItemWithTitle:
					[NSString stringWithFormat: @"%lu %@", (unsigned long) loansCount, (loansCount == 1) ? name : namePlural]]];
				[menu addItem: [NSMenuItem dottedSeparatorItem]];
				spacerNeeded = YES;
			}
		
			NSDate *previousDueDate = [NSDate distantPast];
			NSMenu *loansMenu		= menu;
			int i					= 0;
			
			
			if (menuIconView.compactDisplayMode && loans.count > 0)
			{
				loansMenu = [NSMenu menu];
				[[menu addItemWithTitle: @"Loans"] setSubmenu: loansMenu];;
			}
			
			for (Loan *loan in loans)
			{
				LoansView *view = [[[LoansView alloc] initWithFrame: NSMakeRect(0, 0, menuWidth, 40)] autorelease];
				[view setLoan: loan];

				if ([loan.dueDate isEqualToDate: previousDueDate] == NO)
				{
					[view setDueDateHidden: NO];
					if (i > 0 && [loansMenu numberOfItems] > 0)
					{
						[loansMenu addItem: [NSMenuItem dottedSeparatorItem]];
					}
				}
				else
				{
					[view setDueDateHidden: YES];
				}
				previousDueDate = [[loan.dueDate copy] autorelease];

				[loansMenu addItemWithView: view];
				
				// If we have lots of books we create a "More" submenu to hold the
				// overflow items.  This stops the main menu from becoming too long
				i++;
				if (i == menuItemLimit && loansCount > menuItemLimit + 1)
				{
					[loansMenu addItem: [NSMenuItem dottedSeparatorItem]];
					
					loansMenu = [NSMenu menu];
					[[menu addItemWithTitle: @"More Loans"] setSubmenu: loansMenu];
					[menu addItemWithAttributedString: [NSAttributedString tinyDisabledMenuString:
						[NSString stringWithFormat: @" %ld MORE", (long) loansCount - menuItemLimit]]];
					
					previousDueDate = [NSDate distantPast];
				}
			}
		};
		
		NSArray *loans		= [dataStore loansForLibraryCard: libraryCard eBook: NO];
		NSArray *eBookLoans = [dataStore loansForLibraryCard: libraryCard eBook: YES];
		
		NSUInteger loansCount = [loans count];
		NSUInteger eBookLoansCount = [eBookLoans count];
		
		addLoans(loans, @"LOAN", @"LOANS");
		addLoans(eBookLoans, @"EBOOK LOAN", @"EBOOK LOANS");

#ifdef FREE
		// Report back a sucessful update
		if (loansCount > 0)
		{
			[StatusReporter reportStatus: 1 libraryIdentifier: libraryCard.libraryPropertyName];
		}
		else
		{
			[StatusReporter reportStatus: 0 libraryIdentifier: libraryCard.libraryPropertyName];
		}
#endif

		// Holds
		NSArray *holdsReadyForPickup		= [dataStore holdsForLibraryCard: libraryCard readyForPickup: YES eBook: NO];
		NSArray *holdsWaiting				= [dataStore holdsForLibraryCard: libraryCard readyForPickup: NO eBook: NO];
		NSArray *eBookHoldsReadyForPickup	= [dataStore holdsForLibraryCard: libraryCard readyForPickup: YES eBook: YES];
		NSArray *eBookHoldsWaiting			= [dataStore holdsForLibraryCard: libraryCard readyForPickup: NO eBook: YES];
		NSUInteger ready					= [holdsReadyForPickup count];
		NSUInteger waiting					= [holdsWaiting count];
		NSUInteger eBookReady				= [eBookHoldsReadyForPickup count];
		NSUInteger eBookWaiting				= [eBookHoldsWaiting count];
		NSUInteger holdsCount				= ready + waiting + eBookReady + eBookWaiting;
		
		if (holdsCount > 0)
		{
			if (loansCount > 0) [menu addItem: [NSMenuItem spacerItem]];
			[menu addItem: [NSMenuItem dottedSeparatorItem]];
		
			NSMenu *holdsMenu = [NSMenu menu];
			[holdsMenu addItem: [NSMenuItem spacerItem]];
			
			if (ready > 0)
			{
				[holdsMenu addItem: [NSMenuItem sectionItemWithTitle:
					[NSString stringWithFormat: @"%ld READY FOR PICKUP", (long) ready]]];
				[holdsMenu addItem: [NSMenuItem dottedSeparatorItem]];
			
				int i = 0;
				for (Hold *hold in holdsReadyForPickup)
				{
					// Add the hold to menu
					HoldsView *view = [[[HoldsView alloc] initWithFrame: NSMakeRect(0, 0, menuWidth, 40)] autorelease];
					[view setHold: hold];
					[holdsMenu addItemWithView: view];
					if (i < ready - 1) [holdsMenu addItem: [NSMenuItem dottedSeparatorItem]];
					
					i++;
				}
			}
			
			if (waiting > 0)
			{
				if (ready > 0) [holdsMenu addItemWithTitle: @""];
			
				[holdsMenu addItem: [NSMenuItem sectionItemWithTitle:
					[NSString stringWithFormat: @"%ld REQUESTED", (long) waiting]]];
				[holdsMenu addItem: [NSMenuItem dottedSeparatorItem]];
				
				int i = 0;
				for (Hold *hold in holdsWaiting)
				{
					// Add the hold to menu
					HoldsView *view = [[[HoldsView alloc] initWithFrame: NSMakeRect(0, 0, menuWidth, 40)] autorelease];
					[view setHold: hold];
					[holdsMenu addItemWithView: view];
					if (i < waiting - 1) [holdsMenu addItem: [NSMenuItem dottedSeparatorItem]];
					
					i++;
				}
			}
			
			if (eBookReady > 0)
			{
				if (waiting > 0 || ready > 0) [holdsMenu addItemWithTitle: @""];
			
				[holdsMenu addItem: [NSMenuItem sectionItemWithTitle:
					[NSString stringWithFormat: (eBookReady == 1 ? @"%ld EBOOK READY FOR DOWNLOAD" : @"%ld EBOOKS READY FOR DOWNLOAD"), (long) eBookReady]]];
				[holdsMenu addItem: [NSMenuItem dottedSeparatorItem]];
				
				int i = 0;
				for (Hold *hold in eBookHoldsReadyForPickup)
				{
					// Add the hold to menu
					HoldsView *view = [[[HoldsView alloc] initWithFrame: NSMakeRect(0, 0, menuWidth, 40)] autorelease];
					[view setHold: hold];
					[holdsMenu addItemWithView: view];
					if (i < eBookReady - 1) [holdsMenu addItem: [NSMenuItem dottedSeparatorItem]];
					
					i++;
				}
				
				// Add a direct download link for eBook items
				if ([eBookOpac downloadHoldsEnabled])
				{
					[holdsMenu addItem: [NSMenuItem spacerItem]];
					[holdsMenu addItemWithTitle: @"Download Holds" action: @selector(openDownloadHoldsPage:) target: self representedObject: libraryCard];
				}
			}
			
			if (eBookWaiting > 0)
			{
				if (waiting > 0 || ready > 0 || eBookReady > 0) [holdsMenu addItemWithTitle: @""];
			
				[holdsMenu addItem: [NSMenuItem sectionItemWithTitle:
					[NSString stringWithFormat: (eBookWaiting == 1 ? @"%ld EBOOK REQUESTED" : @"%ld EBOOKS REQUESTED"), (long) eBookWaiting]]];
				[holdsMenu addItem: [NSMenuItem dottedSeparatorItem]];
				
				int i = 0;
				for (Hold *hold in eBookHoldsWaiting)
				{
					// Add the hold to menu
					HoldsView *view = [[[HoldsView alloc] initWithFrame: NSMakeRect(0, 0, menuWidth, 40)] autorelease];
					[view setHold: hold];
					[holdsMenu addItemWithView: view];
					if (i < eBookWaiting - 1) [holdsMenu addItem: [NSMenuItem dottedSeparatorItem]];
					
					i++;
				}
			}
			
			[holdsMenu addItem: [NSMenuItem spacerItem]];
			
			// Set the menu label.  It has 3 possible states:
			//		* Holds 1 ready 4 waiting
			//		* Holds 5 ready
			//		* Holds 5 waiting
			[menu addItem: [NSMenuItem spacerItem]];
			[[menu addItemWithTitle: @"Holds"] setSubmenu: holdsMenu];
			
			NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] init] autorelease];
			if (ready > 0)
			{
				[string appendAttributedString: [NSAttributedString tinyDisabledMenuString:
					[NSString stringWithFormat: @"%ld READY", (long) ready]]];
			}
			if (ready > 0 && waiting > 0)
			{
				[string appendAttributedString: [NSAttributedString tinyDisabledMenuString: @"  ●  "]];
			}
			if (waiting > 0)
			{
				[string appendAttributedString: [NSAttributedString tinyDisabledMenuString:
					[NSString stringWithFormat: @"%ld REQUESTED", (long) waiting]]];
			}
			if (eBookReady)
			{
				if (ready > 0 || waiting > 0)
				{
					[string appendAttributedString: [NSAttributedString tinyDisabledMenuString: @"  ●  "]];
				}
				
				[string appendAttributedString: [NSAttributedString tinyDisabledMenuString:
					[NSString stringWithFormat: (eBookReady == 1 ? @"%ld EBOOK READY" : @"%ld EBOOKS"), (long) eBookReady]]];
			}
			if (eBookWaiting)
			{
				if (ready > 0 || waiting > 0 || eBookReady > 0)
				{
					[string appendAttributedString: [NSAttributedString tinyDisabledMenuString: @"  ●  "]];
				}
				
				[string appendAttributedString: [NSAttributedString tinyDisabledMenuString:
					[NSString stringWithFormat: (eBookWaiting == 1 ? @"%ld EBOOK REQUESTED" : @"%ld EBOOKS REQUESTED"), (long) eBookWaiting]]];
			}
			[menu addItemWithAttributedString: string];
		}
		
		// Display this text when there are no loans or holds
		if ([libraryCard.authenticationOK boolValue] && loansCount + eBookLoansCount + holdsCount == 0)
		{
			[menu addItem: [NSMenuItem sectionItemWithTitle: @"0 LOANS  ●  0 HOLDS"]];
		}
		
		[menu addItem: [NSMenuItem spacerItem]];
		[menu addItem: [NSMenuItem separatorItem]];
		
		// Detect a working generic
		if ([libraryCard.libraryPropertyName hasPrefix: @"generic."] && loansCount > 1 && holdsCount > 1)
		{
			workingGeneric = YES;
		}
	}
	
	// Display the "Share" button if the user has a working generic configuration
//	if (workingGeneric)
//	{
//		[menu addItemWithView: shareSettingsView];
//		[menu addItem: [NSMenuItem separatorItem]];
//	}
	
//	[buttonView removeFromSuperview];
//	[menu addItemWithView: buttonView];
	
	// Settings sub menu
	NSMenu *settingsMenu = [NSMenu menu];
	[settingsMenu addItemWithTitle: @"Print..." action: @selector(print:) target: self];
	[settingsMenu addSeparatorItem];
	[settingsMenu addItemWithTitle: @"About Library Books" action: @selector(showAboutPanel:) target: self];
	NSMenuItem *preferencesMenuItem = [settingsMenu addItemWithTitle: @"Preferences..." action: @selector(display:) target: preferences];
	if ([libraryCards count] == 0)
	{
		[preferencesMenuItem setImage: [NSImage imageNamed: @"RedArrowRight"]];
	}
//	[settingsMenu addItemWithTitle: @"Help" action: @selector(showHelp:)];
	[settingsMenu addItemWithTitle: @"Save Debug..." action: @selector(sendDebug:) target: self];
	[settingsMenu addSeparatorItem];
	[settingsMenu addItemWithTitle: @"Quit Library Books" action: @selector(terminate:)];
	
	NSMenuItem *settingsMenuItem = [menu addItemWithImage: [NSImage imageNamed: @"Gear" ]];
	[settingsMenuItem.image setTemplate: YES];
	[settingsMenuItem setSubmenu: settingsMenu];
	
	[StatusReporter delayStatusReportsForADay];
	
//	[pool drain];
}

- (void) refreshLastUpdated
{
	NSAttributedString *title = [self lastUpdateTimeDescription];
	if (title != nil)
	{
		//	NSString *lastUpdatedString = [[_myki.lastUpdated timeAgoString] uppercaseString];
		//	[_updateMenuItem setAttributedTitle: [NSAttributedString tinyMenuStringAtNormalHeight: title]];
		[_updateMenuItem setAttributedTitle: title];
	}
}

/*
- (void) redrawLastUpdateTime
{
	NSAttributedString *title = [self lastUpdateTimeDescription];
	if (title != nil)
	{
		[lastUpdateMenuItem setAttributedTitle: title];
	}
}
*/

- (NSAttributedString *) lastUpdateTimeDescription
{
	if (preferences.lastUpdateTime == nil || [preferences.lastUpdateTime isEqualToDate: [NSDate distantPast]]) return nil;

	NSString *timeAgoString = [preferences.lastUpdateTime timeAgoString];

	NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] init] autorelease];
//	[string appendAttributedString: [NSAttributedString tinyMenuStringAtNormalHeight:  @"LASTED UPDATED "]];
	[string appendAttributedString: [NSAttributedString tinyMenuStringAtNormalHeight:  [timeAgoString uppercaseString]]];
	
	return string;
	
/*	NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] init] autorelease];
	[string appendAttributedString: [NSAttributedString tinyItalicDisabledMenuString:  @"last update  "]];
	[string appendAttributedString: [NSAttributedString tinyDisabledMenuString:  [timeAgoString uppercaseString]]];
	
	return string; */
}

// Updating and animation ------------------------------------------------------

- (IBAction) update: (id) selector
{
	if ([[Reachability sharedReachability] internetConnectionStatus] == NotReachable)
	{
		[Debug saveLogToDisk];
		[Debug log: @"Skipping update because no network connection"];
		return;
	}

	if (updating) return;
	updating = YES;
	
	// Replace the normal "Update" menu item with a progress indicator
	UpdatingView *view = [UpdatingView updatingViewWithWidth: 400];
	[_updateMenuItem setView: view];
	
	dispatch_queue_t main = dispatch_get_main_queue();
	dispatch_queue_t queue = dispatch_queue_create("au.id.haroldchu.mac.librarybooks.Update", NULL);
	
	dispatch_async(queue,
	^{
		// Do the update
		[dataStore update];
		
		// Call the selector on the main thread
		dispatch_async(main,
		^{
			preferences.lastUpdateTime = [NSDate date];
		
			[self redrawStatusItem];
			[self redrawStatusMenu];
			
			// Restore the "Update" menu item
			[self refreshLastUpdated];
			[_updateMenuItem setView: nil];
			
			[Debug divider];
			
			[[Calendar sharedCalendar] update];
			[[Growl sharedGrowl] update];
			
			[Debug saveLogToDisk];
			
			updating = NO;
		});
	});

/*
	if (updating == NO)
	{
		updating = YES;
		
		// Replace the normal "Update" menu item with a progress indicator
		UpdatingView *view = [UpdatingView updatingViewWithWidth: 400];
		[_updateMenuItem setView: view];
		
		[NSThread detachNewThreadSelector: @selector(updateThread:) toTarget: self withObject: nil];
	}*/
}

- (IBAction) openLibraryWebPage: (id) selector
{
	OPAC<OPAC> *opac = [OPAC opacForIdentifier: [selector representedObject]];
	[opac.webPageURL openInWebBrowser];
}

- (IBAction) openMyAccountPage: (id) selector
{
	[self openMyAccountPageForLibraryCard: [selector representedObject] eBook: NO];
}

- (IBAction) openMyEBookAccountPage: (id) selector
{
	[self openMyAccountPageForLibraryCard: [selector representedObject] eBook: YES];
}

- (void) openMyAccountPageForLibraryCard: (LibraryCard *) libraryCard eBook: (BOOL) eBook
{
	OPAC *opac = (eBook) ? [OPAC eBookOpacForLibraryCard: libraryCard]
		: [OPAC opacForLibraryCard: libraryCard];
	if ([opac respondsToSelector: @selector(myAccountURL)] == NO) return;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	libraryCard = opac.libraryCard;
	[Debug setSecretStrings: [NSArray arrayWithObjects: libraryCard.authentication1,
		libraryCard.authentication2, libraryCard. authentication3, nil]];

	[Debug divider];
	[Debug log: @"Opening my account page [%@] [%@]", libraryCard.name, libraryCard.libraryPropertyName];
	[Debug space];
	
	URL *url = [opac performSelector: @selector(myAccountURL)];
	if (url)
	{
		[Debug logDetails: [[url attributes] description] withSummary: @"My account URL - %@", url];
		[url openInWebBrowser];
	}
	else
	{
		[Debug logError: @"My account URL - NULL"];
	}
	
	[Debug saveLogToDisk];
	
	[pool release];
}

- (IBAction) openRenewItemsPage: (id) selector
{	
	OPAC *opac = [OPAC opacForLibraryCard: [selector representedObject]];
	if ([opac respondsToSelector: @selector(renewItemsURL)] == NO) return;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	URL *url = [opac performSelector: @selector(renewItemsURL)];
	if (url)
	{
		[url openInWebBrowser];
	}
	
	[pool release];
}

- (void) openDownloadHoldsPage: (id) selector
{
	OPAC *opac = [OPAC eBookOpacForLibraryCard: [selector representedObject]];
	if ([opac respondsToSelector: @selector(downloadHoldsURL)] == NO) return;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	LibraryCard *libraryCard = opac.libraryCard;
	[Debug setSecretStrings: [NSArray arrayWithObjects: libraryCard.authentication1,
		libraryCard.authentication2, libraryCard. authentication3, nil]];

	[Debug divider];
	[Debug log: @"Opening my eBooks download holds page [%@] [%@]", libraryCard.name, libraryCard.libraryPropertyName];
	[Debug space];
	
	URL *url = [opac performSelector: @selector(downloadHoldsURL)];
	if (url)
	{
		[Debug logDetails: [[url attributes] description] withSummary: @"My eBook account holds URL - %@", url];
		[url openInWebBrowser];
	}
	else
	{
		[Debug logError: @"My eBook account holds URL - NULL"];
	}
	
	[Debug saveLogToDisk];
	
	[pool release];
}

- (void) openURL: (id) sender
{
	URL *url = [sender representedObject];
	[url openInWebBrowser];
}

- (void) copyToClipboard: (id) sender
{
	NSPasteboard *clipboard = [NSPasteboard generalPasteboard];
	NSString *string		= [sender representedObject];
	NSArray *types			= [NSArray arrayWithObjects:NSStringPboardType, nil];
	
	[clipboard declareTypes: types owner: self];
    [clipboard setString: string forType: NSStringPboardType];
}

/*
- (void) updateThread: (id) sender
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
//	dataStore.context2Thread = [NSThread currentThread];
//	[dataStore lock];
	
	// Do the update
	[dataStore update];
	preferences.lastUpdateTime = [NSDate date];
	
//	[dataStore unlock];
	
	[self redrawStatusItem];
	[self redrawStatusMenu];
	
	// Restore the "Update" menu item
	[self refreshLastUpdated];
	[_updateMenuItem setView: nil];
	
	[Debug divider];
	
	[[Calendar sharedCalendar] update];
	[[Growl sharedGrowl] update];
	
	[Debug saveLogToDisk];
	
	updating = NO;
	
//	dataStore.context2Thread = nil;
	
	[pool drain];
}
*/

// -----------------------------------------------------------------------------
//
// Display the about box.  We need to format the credits text manually to
// dynamically link to the Legal.html file.
//
// -----------------------------------------------------------------------------
- (IBAction) showAboutPanel: (id) sender
{
	// Dismiss the calling menu
//	NSMenu* menu = [[sender enclosingMenuItem] menu];
//	[menu cancelTracking];
	
	// Open the about box
#ifdef APP_STORE
	NSString *bundlePath	= [[NSBundle mainBundle] bundlePath];
	NSString *href			= [bundlePath stringByAppendingString: @"/Contents/Resources/LegalAppStore.html"];
#else
	NSString *bundlePath	= [[[NSBundle mainBundle] bundlePath] stringByReplacingOccurrencesOfString: @"β" withString: @"%CE%B2"];
	NSString *href			= [bundlePath stringByAppendingString: @"/Contents/Resources/Legal.html"];
#endif
	NSAttributedString *credits = [NSAttributedString htmlString: [NSString stringWithFormat:
		@"<html><head><style> \
			body {font: 10px 'Lucida Grande'} \
			p {text-align: justify} \
		</head></style> \
		<body><a href=\"file://%@\">Legal</a></body></html>",
		href]
	];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
		credits, @"Credits",
		nil
	];
	[NSApp orderFrontStandardAboutPanelWithOptions: options];
	[NSApp activateIgnoringOtherApps: YES];
}

- (IBAction) shareGenericSettings: (id) sender
{
	// Dismiss the calling menu
	NSMenu* menu = [[sender enclosingMenuItem] menu];
	[menu cancelTracking];
	
	NSArray *libraryCards = [dataStore selectLibraryCards];
	for (LibraryCard *libraryCard in libraryCards)
	{
		if ([libraryCard.libraryPropertyName hasPrefix: @"generic."])
		{
			NSDictionary *overrideProperies = [NSKeyedUnarchiver unarchiveObjectWithData: libraryCard.overrideProperties];
		
			NSString *comment = [NSString stringWithFormat:
				@"I got this generic library working:\n" \
				@"\n" \
				@"* Catalogue: %@\n" \
				@"* Catalogue URL: %@\n" \
				@"* Date Format: %@",
				libraryCard.libraryPropertyName,
				[overrideProperies objectForKey: @"CatalogueURL"],
				[overrideProperies objectForKey: @"DateFormat"]
			];
			
			URL *url = [URL URLWithFormat: @"http://librarybooksapp.com/request.cgi?a=request-html&comment=%@",
				[comment URLEncode]];
			[url openInWebBrowser];
		
			break;
		}
	}
}

// =============================================================================
#pragma mark -
#pragma mark Debug

// -----------------------------------------------------------------------------
//
// Display debug reporter.
//
// -----------------------------------------------------------------------------
- (IBAction) sendDebug: (id) sender
{
	// Dismiss the calling menu
//	NSMenu* menu = [[sender enclosingMenuItem] menu];
//	[menu cancelTracking];
	
	// Use a timer to display the dialog.  This allows the menu to be closed
	// because the alert box is modal
	[NSTimer scheduledTimerWithTimeInterval: 0 target: self
		selector: @selector(debugTimerAction:) userInfo: nil repeats: NO];
}

- (void) debugTimerAction: (NSTimer *) timer
{
//	// Display the alert
//	NSAlert *alert = [NSAlert
//		alertWithMessageText:		@"Report Problem"
//		defaultButton:				@"Close"
//		alternateButton:			@"Save Debug File..."
//		otherButton:				nil
//		informativeTextWithFormat:
//			@"Report a problem by sending an email to librarybooks@haroldchu.id.au. " \
//			@"My name is Harold and I'm the author of this app. Please attach a copy of the debug. You can save the debug using the button below."
//	];
//	NSInteger returnCode = [alert runModal];
//	if (returnCode == NSAlertAlternateReturn)
//	{
		// Ask the user for the file name
		NSFileManager *fileManager	= [NSFileManager defaultManager];
		NSSavePanel *savePanel		= [NSSavePanel savePanel];
		
		[savePanel setDelegate: self];
		[savePanel setNameFieldStringValue: @"Library Books Debug.html.gz"];
		[savePanel setDirectoryURL: [fileManager desktopDirectoryURL]];
		
		NSInteger savePanelReturnCode = [savePanel runModal];
		if (savePanelReturnCode == NSFileHandlingPanelOKButton)
		{
			// Save debug file
			NSURL *fromURL	= [NSURL fileURLWithPath: [Debug gzippedLogFilePath]];
			NSURL *toURL	= [savePanel URL];
			
			NSError *error = nil;
			if ([fileManager fileExistsAtPath: [toURL path]])
			{
				[fileManager removeItemAtURL: toURL error: &error];
				if (error) NSLog(@"Error removing old file: %@", [error description]);
			}
			
			error = nil;
			[fileManager copyItemAtURL: fromURL toURL: toURL error: &error];
			if (error) NSLog(@"Error saving: %@", [error description]);
		}
//	}
}

// =============================================================================
#pragma mark -
#pragma mark Tooltip

// -----------------------------------------------------------------------------
//
// Rollover actions for the tooltip next to the icons.
//
// -----------------------------------------------------------------------------
- (void) mouseEntered: (NSEvent *) event
{
	NSButton *sender = [(id) [event userData] objectForKey: @"sender"];
	
	NSString *tooltip = @"";
	if		(sender == quitButton)			tooltip = @"Quit Library Books";
	else if (sender == preferencesButton)	tooltip = @"Preferences...";
	else if (sender == printButton)			tooltip = @"Print...";
	else if (sender == aboutButton)			tooltip = @"About Library Books";
	else if (sender == debugButton)			tooltip = @"Save Debug Report...";

	[tooltipLabel setStringValue: [tooltip uppercaseString]];
}

- (void) menuOpen: (NSEvent *) event
{
	[[Spotlight sharedSpotlight] hideSpotlight];
}

- (void) menuClose: (NSEvent *) event
{
	[tooltipLabel setStringValue: @""];
}

// =============================================================================
#pragma mark -
#pragma mark Printing

- (void) print: (id) sender
{
	// Dismiss the calling menu
//	NSMenu* menu = [[sender enclosingMenuItem] menu];
//	[menu cancelTracking];
	
	// Use a timer to display the dialog.  This allows the menu to be closed
	// because the alert box is modal
	[NSTimer scheduledTimerWithTimeInterval: 0 target: self
		selector: @selector(printTimerAction:) userInfo: nil repeats: NO];
}

- (void) printTimerAction: (NSTimer *) timer
{
	NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] init] autorelease];
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat: @"EEE\td MMM"];
	
	NSArray *libraryCards = [dataStore selectLibraryCards];
	for (LibraryCard *libraryCard in libraryCards)
	{
		[string appendAttributedString: [NSAttributedString boldMenuString: libraryCard.name]];
		[string appendAttributedString: [NSAttributedString normalMenuString:@"\n"]];
		
		// Loans
		NSArray *loans = [dataStore loansForLibraryCard: libraryCard eBook: NO];
		for (Loan *loan in loans)
		{
			NSString *date = [dateFormatter stringFromDate: loan.dueDate];
		
			[string appendAttributedString: [NSAttributedString normalMenuString: @"☐  "]];
			[string appendAttributedString: [NSAttributedString normalMenuString: date]];
			[string appendAttributedString: [NSAttributedString normalMenuString: @"\t\t"]];
			[string appendAttributedString: [NSAttributedString normalMenuString: loan.title]];
			if (loan.author)
			{
				[string appendAttributedString: [NSAttributedString smallDisabledMenuString: @" / "]];
				[string appendAttributedString: [NSAttributedString smallDisabledMenuString: loan.author]];
			}
			[string appendAttributedString: [NSAttributedString normalMenuString:@"\n"]];
		}
		
		[string appendAttributedString: [NSAttributedString normalMenuString:@"\n"]];
	}
	
	// Print properties
	NSPrintInfo *printInfo = [[[NSPrintInfo sharedPrintInfo] copy] autorelease];
	[printInfo setHorizontalPagination:	NSFitPagination];
	[printInfo setLeftMargin:			40];
	[printInfo setRightMargin:			40];
	[printInfo setTopMargin:			40];
	[printInfo setBottomMargin:			40];
	[printInfo setVerticallyCentered:	NO];
	
	NSMutableParagraphStyle *paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[paragraphStyle setHeadIndent: 140];
	[paragraphStyle setFirstLineHeadIndent: 0];
	[string addAttribute: NSParagraphStyleAttributeName value: paragraphStyle range: NSMakeRange(0, [string length])];
	
	// Create a print view matching the paper size
	NSSize paperSize = [printInfo paperSize];
	NSTextView *view = [[[NSTextView alloc] initWithFrame: NSMakeRect(0, 0, paperSize.width, paperSize.height)] autorelease];
	[[view textStorage] setAttributedString: string];

	// Print
	NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView: view printInfo: printInfo];
	[printOperation runOperation];
}

// =============================================================================
#pragma mark -
#pragma mark Timer and auto updating

// -----------------------------------------------------------------------------
//
// Setup a timer to fire every minute.
//
// -----------------------------------------------------------------------------
- (void) setupTimer
{
	[NSTimer scheduledTimerWithTimeInterval: 40 target: self
		selector: @selector(timerAction:) userInfo: nil repeats: YES];
}

- (void) timerAction: (NSTimer *) timer
{
	static int previousHour = -1;
	
	if (preferences.autoUpdate == YES
		&& updating == NO
		&& (preferences.lastUpdateTime == nil || -[preferences.lastUpdateTime timeIntervalSinceNow] > preferences.autoUpdateInterval))
	{
		[self update: nil];
	}
	else
	{
		int currentHour = [[NSCalendarDate date] hourOfDay];
		if (previousHour != currentHour)
		{		
			// Update the menu to ensure that warning colours take effect
			[self redrawStatusItem];
			[self redrawStatusMenu];
							
			previousHour = currentHour;
		}
		
		[self refreshLastUpdated];
	}
}

@end