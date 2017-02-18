#import "DottedSeparatorView.h"
#import "NSColorExtras.h"

@implementation DottedSeparatorView

#define MARGIN_LEFT		22
#define MARGIN_RIGHT	10

- (id) initWithFrame: (NSRect) frame
{
	self = [super initWithFrame: frame];
	if (self)
	{
		[self setAutoresizingMask: NSViewWidthSizable];
	}
	return self;
}

- (void) dealloc
{
	[path release];
	[super dealloc];
}

- (void) drawRect: (NSRect) frame
{
	if (path == nil)
	{
		CGFloat y = (int) frame.size.height / 2;
	
		path = [[NSBezierPath bezierPath] retain];
		[path moveToPoint: NSMakePoint(MARGIN_LEFT, y + 0.5)];
		[path lineToPoint: NSMakePoint(frame.size.width - MARGIN_LEFT - MARGIN_RIGHT, y + 0.5)];
		[path setLineWidth: 1];
		
		CGFloat dash[2] = {1, 4};
		[path setLineDash: dash count: 2 phase: 0];
	}
	
	[[NSColor colorWithCalibratedWhite: 0 alpha: 0.3] set];
	[path stroke];
}

@end