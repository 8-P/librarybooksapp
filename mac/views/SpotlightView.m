#import "SpotlightView.h"

#define MASK_ALPHA			0.7
#define CIRCLE_RADIUS		50
#define CIRCLE_DIAMETER		(CIRCLE_RADIUS * 2)

@implementation SpotlightView

@synthesize center;

- (id) initWithFrame: (NSRect) frame
{
    self = [super initWithFrame: frame];
    return self;
}

- (void) drawRect: (NSRect) rect
{
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
    
    // This causes the paths we append to act as holes in the overall path
    [path setWindingRule: NSEvenOddWindingRule];
    
	// Draw circle
	NSRect circleRect = NSMakeRect(center.x - CIRCLE_RADIUS, center.y - CIRCLE_RADIUS * 1.5, CIRCLE_DIAMETER, CIRCLE_DIAMETER);
	[path appendBezierPathWithOvalInRect: NSInsetRect(circleRect, (NSWidth(circleRect) - CIRCLE_DIAMETER) / 2.0, (NSHeight(circleRect) - CIRCLE_DIAMETER) / 2.0)];

    // Fill the entire space with clear
    [[NSColor clearColor] setFill];
    NSRectFill(rect);
	
    // Draw the mask
    [[NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: MASK_ALPHA] setFill];
    [path fill];
}

@end