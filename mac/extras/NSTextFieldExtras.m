#import "NSTextFieldExtras.h"

@implementation NSTextField (NSTextFieldExtras)

+ (NSTextField *) tinyLabelWithFrame: (NSRect) frame
{
	return [NSTextField tinyLabelWithFrame: frame alignment: NSLeftTextAlignment];
}

+ (NSTextField *) tinyLabelWithFrame: (NSRect) frame alignment: (NSTextAlignment) alignment
{
	NSTextField *label = [[[NSTextField alloc] initWithFrame: frame] autorelease];
	
	[label setEditable:			NO];
	[label setBordered:			NO];
	[label setSelectable:		NO];
	[label setAlignment:		alignment];
	[label setFont:				[NSFont systemFontOfSize: 9]];
	[label setBackgroundColor:	[NSColor clearColor]];
	
	return label;
}

+ (NSTextField *) boldLabelWithFrame: (NSRect) frame
{
	return [NSTextField boldLabelWithFrame: frame alignment: NSLeftTextAlignment];
}

+ (NSTextField *) boldLabelWithFrame: (NSRect) frame alignment: (NSTextAlignment) alignment
{
	NSTextField *label = [[[NSTextField alloc] initWithFrame: frame] autorelease];
	
	[label setEditable:			NO];
	[label setBordered:			NO];
	[label setSelectable:		NO];
	[label setAlignment:		alignment];
	[label setFont:				[NSFont boldSystemFontOfSize: 14]];
	[label setBackgroundColor:	[NSColor clearColor]];
	
	return label;
}

+ (NSTextField *) menuLabelWithFrame: (NSRect) frame
{
	return [NSTextField menuLabelWithFrame: frame alignment: NSLeftTextAlignment];
}

+ (NSTextField *) menuLabelWithFrame: (NSRect) frame alignment: (NSTextAlignment) alignment
{
	NSTextField *label = [[[NSTextField alloc] initWithFrame: frame] autorelease];
	
	[label setEditable:			NO];
	[label setBordered:			NO];
	[label setSelectable:		NO];
	[label setAlignment:		alignment];
	[label setFont:				[NSFont menuFontOfSize: 14]];
	[label setBackgroundColor:	[NSColor clearColor]];
	
	return label;
}

+ (NSTextField *) menuLabelWithFrame: (NSRect) frame size: (CGFloat) size
{
	NSTextField *label = [[[NSTextField alloc] initWithFrame: frame] autorelease];
	
	[label setEditable:			NO];
	[label setBordered:			NO];
	[label setSelectable:		NO];
	[label setFont:				[NSFont menuFontOfSize: size]];
	[label setBackgroundColor:	[NSColor clearColor]];
	
	return label;
}

@end