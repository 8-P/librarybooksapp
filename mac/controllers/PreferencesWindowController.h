#import <Cocoa/Cocoa.h>
#import "ComboSecureTextField.h"

@interface PreferencesWindowController : NSWindowController
	<CLLocationManagerDelegate, NSTextFieldDelegate, NSTabViewDelegate, NSWindowDelegate,
	NSTableViewDelegate, NSTableViewDataSource>
{
	IBOutlet NSUserDefaultsController *userDefaultsController;

	IBOutlet NSView				*libraryCardsView;
	IBOutlet NSView				*generalView;
	IBOutlet NSView				*menuView;
	IBOutlet NSView				*alertsView;
	IBOutlet NSView				*advancedView;
	IBOutlet NSView				*iPhoneView;
	IBOutlet NSView				*donateView;
	
	IBOutlet NSToolbar			*toolbar;
	IBOutlet NSArrayController	*libraryCardsArrayController;
	IBOutlet NSTableView		*libraryCardsTableView;
	
	// General tab
	IBOutlet NSButton			*startAtLogin;
	
	// Update
	IBOutlet NSWindow			*updateWindow;
	NSInvocationOperation		*updateOperation;
	IBOutlet NSProgressIndicator *updateProgressIndicator;
	BOOL						checkedForUpdate;
	
	// Edit library card
	IBOutlet NSWindow			*editLibraryCardWindow;
	IBOutlet NSTabView			*editLibraryCardTabView;
	IBOutlet NSTabViewItem		*editLibraryCardTabViewItemLibraryCard;
	IBOutlet NSTabViewItem		*editLibraryCardTabViewItemOPACSettings;
	IBOutlet NSTabViewItem		*editLibraryCardTabViewItemOPACClickHere;
	
	IBOutlet NSPopUpButton		*librariesPopUpButton;
	
	IBOutlet NSTextField		*authenticationDisplayName;
	
	IBOutlet NSTextField		*authentication1Title;
	IBOutlet NSTextField		*authentication2Title;
	IBOutlet NSTextField		*authentication3Title;
	
	IBOutlet ComboSecureTextField *authentication1Value;
	IBOutlet ComboSecureTextField *authentication2Value;
	IBOutlet ComboSecureTextField *authentication3Value;
	
	IBOutlet NSTextField		*noteTextField;
	
	IBOutlet NSTextField		*catalogueURL;
	IBOutlet NSTextField		*catalogueURLExampleTextField;
	IBOutlet NSPopUpButton		*dateFormatButton;
	
	IBOutlet NSButton			*saveButton;
	
	NSString					*opacIdentifier;
	CLLocation					*currentLocation;
	CLLocationManager			*locationManager;
}

@property(readonly)	BOOL			autoUpdate;
@property(readonly)	NSTimeInterval	autoUpdateInterval;
@property(retain)	NSDate			*lastUpdateTime;

- (IBAction) display: (id) sender;
- (IBAction) editLibraryCard: (id) sender;
- (IBAction) addLibraryCard: (id) sender;
- (IBAction) closeEditLibraryCard: (id) sender;
- (IBAction) saveEditLibraryCard: (id) sender;

- (void) updateLibrariesMenu;
- (void) appendMenuItemsTo: (NSMenu *) menu forPath: (NSString *) path indentationLevel: (NSUInteger) indentationLevel type: (NSString *) type;
- (void) updateDateFormatsMenu;
- (void) redrawAuthentication;
- (void) redrawTabs;
- (NSArray *) nearbyLibraries;
- (void) updateSaveEnabled;
- (void) updateGenericCatalogueSettings;
- (void) updateDisplayNameFromIdentifer: (NSString *) oldIdentifier toIdentifier: (NSString *) newIdentifier;

- (IBAction) startAtLogin: (id) sender;

- (IBAction) showLibraryCardsView: (id) sender;
- (IBAction) showLibraryGeneralView: (id) sender;
- (IBAction) showLibraryMenuView: (id) sender;
- (IBAction) showAlertsView: (id) sender;
- (IBAction) showLibraryAdvancedView: (id) sender;
- (IBAction) showiPhoneView: (id) sender;
- (IBAction) showBuyView: (id) sender;
- (void) setPreferencesView: (NSView*) view resizable: (BOOL) resizable;
- (void) restoreViewHeight: (NSView *) view withItemIdentifier: (NSString *) identifier;

- (void) updateThenEditLibraryCard;
- (IBAction) cancelUpdate: (id) sender;
- (void) displayEditLibraryCard;

- (IBAction) openIOSAppStore: (id) sender;
- (IBAction) openMacAppStore: (id) sender;

- (IBAction) postConfigurationChangedNotification:(id)sender;

@end