#import "NSImageExtras.h"

@implementation NSImage (NSImageExtras)

// -----------------------------------------------------------------------------
//
// Colourise the image.  This is used to make the icon green and red to alert
// the user.
//
// -----------------------------------------------------------------------------
- (NSImage *) imageWithColour: (NSColor *) colour
{
	NSSize size		= [self size];
	NSRect rect		= NSMakeRect(0, 0, size.width, size.height);
	NSImage *image	= [self copy];
	
	[image lockFocus];
	
	[image drawAtPoint: NSZeroPoint fromRect: rect operation: NSCompositeSourceOver fraction: 1.0];
	[colour set];
	NSRectFillUsingOperation(rect, NSCompositeSourceAtop);
	
	[image unlockFocus];
	
	return [image autorelease];
}

@end