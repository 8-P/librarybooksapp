#import "Spotlight.h"

@implementation Spotlight

@synthesize view;

- (void) dealloc
{
	[spotlightView release];
	[super dealloc];
}

- (void) displaySpotlightAt: (NSPoint) point
{
	NSRect screenRect = [[NSScreen mainScreen] frame];
	self.window = [[NSWindow alloc] initWithContentRect: screenRect
		styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO];
	[self.window setBackgroundColor: [NSColor clearColor]];
	[self.window setOpaque: NO];
	[self.window setIgnoresMouseEvents: YES];
	[self.window setLevel: CGWindowLevelForKey(kCGOverlayWindowLevelKey)];
	
	spotlightView = [[SpotlightView alloc] initWithFrame: [self.window frame]];
	spotlightView.center = point;
	[self.window setContentView: spotlightView];
	
	NSSize size = [view frame].size;
	[view setFrameOrigin: NSMakePoint(point.x - size.width/2, point.y - size.height - 100)];
	[spotlightView addSubview: view];
	
	[self.window makeKeyAndOrderFront: nil];
	
	[NSTimer scheduledTimerWithTimeInterval: 20 target: self
		selector: @selector(timerAction:) userInfo: nil repeats: NO];
}

- (void) hideSpotlight
{
	[self.window orderOut: nil];
}

- (void) timerAction: (NSTimer *) timer
{
	[self hideSpotlight];
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static Spotlight *sharedSpotlight = nil;

+ (Spotlight *) sharedSpotlight
{
    @synchronized(self)
	{
        if (sharedSpotlight == nil)
		{
            sharedSpotlight= [[Spotlight alloc] init];
        }
    }
	
    return sharedSpotlight;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedSpotlight == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedSpotlight;
}

- (id) copyWithZone:(NSZone *)zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (NSUInteger) retainCount
{
	// Denotes an object that cannot be released
    return NSUIntegerMax;
}

- (oneway void) release
{
    // Do nothing
}

- (id) autorelease
{
    return self;
}

@end