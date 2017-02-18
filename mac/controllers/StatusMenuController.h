#import <Cocoa/Cocoa.h>
#import "DataStore.h"
#import "PreferencesWindowController.h"
#import "MenuIconView.h"

@interface StatusMenuController : NSWindowController <NSOpenSavePanelDelegate, NSMenuDelegate>
{
	NSUserDefaults			*defaults;

	NSStatusItem			*statusItem;
	NSMenu					*statusMenu;
//	NSMenuItem				*lastUpdateMenuItem;
	NSMenuItem *_updateMenuItem;
	MenuIconView			*statusItemView;
	
	BOOL					updating;

	DataStore				*dataStore;

	IBOutlet NSView			*buttonView;
	IBOutlet NSButton		*quitButton;
	IBOutlet NSButton		*preferencesButton;
	IBOutlet NSButton		*aboutButton;
	IBOutlet NSButton		*debugButton;
	IBOutlet NSButton		*printButton;
	IBOutlet NSTextField	*tooltipLabel;
	
	IBOutlet NSView			*shareSettingsView;
	IBOutlet NSView			*spotlightMessageView;
	
	
	BOOL menuUpdateNeeded; 
	
	IBOutlet PreferencesWindowController *preferences;
}

- (void) setupTooltips;
- (void) setupStatusItem;
- (void) displaySpotlightForBeginners;
- (void) redrawStatusItem;
- (void) redrawStatusMenu;
//- (void) redrawLastUpdateTime;
- (NSAttributedString *) lastUpdateTimeDescription;

- (IBAction) showAboutPanel: (id) sender;
- (IBAction) shareGenericSettings: (id) sender;
- (IBAction) sendDebug: (id) sender;
- (IBAction) print: (id) sender;
- (void) printTimerAction: (NSTimer *) timer;

- (void) openMyAccountPageForLibraryCard: (LibraryCard *) libraryCard eBook: (BOOL) eBook;
- (void) setupTimer;

@end