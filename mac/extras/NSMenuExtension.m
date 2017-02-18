#import "NSMenuExtension.h"
#import "NSAttributedStringExtension.h"

@implementation NSMenu (NSMenuExtension)

+ (NSMenu *) menu
{
	return [[[NSMenu alloc] init] autorelease];
}

- (void) addSeparatorItem
{
	[self addItem: [NSMenuItem separatorItem]];
}

- (NSMenuItem *) addItemWithTitle: (NSString *) title action: (SEL) selector
{
	return [self addItemWithTitle: title action: selector keyEquivalent: @""];
}

- (NSMenuItem *) addItemWithTitle: (NSString *) title
{
	return [self addItemWithTitle: title action: nil keyEquivalent: @""];
}

- (NSMenuItem *) addItemWithTitle: (NSString *) title action: (SEL) selector target: (id) target
{
	NSMenuItem *menuItem = [self addItemWithTitle: title action: selector keyEquivalent: @""];
	[menuItem setTarget: target];
	
	return menuItem;
}

- (NSMenuItem *) addItemWithTitle: (NSString *) title action: (SEL) selector target: (id) target representedObject: (id) representedObject
{
	NSMenuItem *menuItem = [self addItemWithTitle: title action: selector keyEquivalent: @""];
	[menuItem setTarget: target];
	[menuItem setRepresentedObject: representedObject];
	
	return menuItem;
}

- (NSMenuItem *) addItemWithImage: (NSImage *) image
{
	NSMenuItem *menuItem = [self addItemWithTitle: @""];
	[menuItem setImage: image];
	
	return menuItem;
}

- (NSMenuItem *) addItemWithBoldTitle: (NSString *) title
{
	NSAttributedString *string = [NSAttributedString boldMenuString: title];
	return [self addItemWithAttributedString: string];
}

- (NSMenuItem *) addItemWithTitleFormat: (NSString *) format, ...
{
	// Build up the string
	va_list arguments;
	va_start(arguments, format);
	NSString *string = [[NSString alloc] initWithFormat: format arguments: arguments];
	[string autorelease];
	va_end(arguments);
	
	return [self addItemWithTitle: string action: nil keyEquivalent: @""];
}

- (NSMenuItem *) addItemWithBoldTitleFormat: (NSString *) format, ...
{
	// Build up the string
	va_list arguments;
	va_start(arguments, format);
	NSString *string = [[NSString alloc] initWithFormat: format arguments: arguments];
	[string autorelease];
	va_end(arguments);
	
	return [self addItemWithBoldTitle: string];
}

- (NSMenuItem *) addItemWithAttributedString: (NSAttributedString *) string
{
	NSMenuItem *menuItem = [[[NSMenuItem alloc] init] autorelease];
	[menuItem setAttributedTitle: string];
	
	[self addItem: menuItem];
	return menuItem;
}

// Add a menu item is a description underneath.
- (NSMenuItem *) addItemWithTitle: (NSString *) title description: (NSString *) description
{
	NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] init] autorelease];
	[string appendAttributedString: [NSAttributedString normalMenuString: title]];
	[string appendAttributedString: [NSAttributedString normalMenuString: @"\n"]];
	[string appendAttributedString: [NSAttributedString smallMenuString: description]];

	return [self addItemWithAttributedString: string];
}
									 
- (NSMenuItem *) addItemWithView: (NSView *) view
{
	NSMenuItem *menuItem = [self addItemWithTitle: @"" action: nil keyEquivalent: @""];
	[menuItem setView: view];
	
	return menuItem;
}

@end