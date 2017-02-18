#import "NSMenuItemExtras.h"
#import "DottedSeparatorView.h"
#import "SectionView.h"

@implementation NSMenuItem (NSMenuItemExtras)

+ (NSMenuItem *) dottedSeparatorItem
{
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle: @"" action: nil keyEquivalent: @""] autorelease];
	
	DottedSeparatorView *dots = [[DottedSeparatorView alloc] initWithFrame: NSMakeRect(0, 0, 0, 10)];
	[menuItem setView: dots];
	[dots release];
	
	return menuItem;
}

+ (NSMenuItem *) sectionItemWithTitle: (NSString *) title
{
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle: @"" action: nil keyEquivalent: @""] autorelease];
	
	SectionView *section = [[SectionView alloc] initWithFrame: NSMakeRect(0, 0, 0, 16)];
	section.title = title;
	[menuItem setView: section];
	[section release];
	
	return menuItem;
}

+ (NSMenuItem *) spacerItem
{
	NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle: @"" action: nil keyEquivalent: @""] autorelease];
	
	NSView *view = [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 0, 8)];
	[menuItem setView: view];
	[view release];
	
	return menuItem;
}

@end