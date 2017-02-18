#import "ComboSecureTextField.h"

@implementation ComboSecureTextField

@dynamic text, secureTextEntry, placeholder;

- (id) initWithFrame: (NSRect) frame
{
	self = [super initWithFrame: frame];
	if (self)
	{
		textField		= [[NSTextField alloc] initWithFrame: frame];
		secureTextField = [[NSSecureTextField alloc] initWithFrame: frame];
	
		[self setTabViewType: NSNoTabsNoBorder];
	
		NSTabViewItem *textFieldTabViewItem = [[NSTabViewItem alloc] initWithIdentifier: @"textField"];
		[textFieldTabViewItem setView: textField];
		[self addTabViewItem: textFieldTabViewItem];
		[textFieldTabViewItem release];
		
		NSTabViewItem *secureTextFieldTabViewItem = [[NSTabViewItem alloc] initWithIdentifier: @"secureTextField"];
		[secureTextFieldTabViewItem setView: secureTextField];
		[self addTabViewItem: secureTextFieldTabViewItem];
		[secureTextFieldTabViewItem release];
		
		[self selectFirstTabViewItem: nil];
	}
    
	return self;
}

- (void) setSecureTextEntry: (BOOL) secure
{
	[self selectTabViewItemWithIdentifier: (secure) ? @"secureTextField" : @"textField"];
}

- (BOOL) isSecureTextEntry
{
	return [[[self selectedTabViewItem] identifier] isEqualToString: @"secureTextField"];
}

- (void) setText: (NSString *) string
{
	[textField       setStringValue: string];
	[secureTextField setStringValue: string];
}

- (NSString *) text
{
	if ([self isSecureTextEntry])
	{
		return [secureTextField stringValue];
	}
	else
	{
		return [textField stringValue];
	}
}

- (void) setDelegate: (id) delegate
{
	[textField       setDelegate: delegate];
	[secureTextField setDelegate: delegate];
}

- (void) setPlaceholder: (NSString *) string
{
	[[textField       cell] setPlaceholderString: string];
	[[secureTextField cell] setPlaceholderString: string];
}

- (void) dealloc
{
	[textField release];
	[secureTextField release];
	[super dealloc];
}

@end