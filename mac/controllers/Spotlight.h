#import <Cocoa/Cocoa.h>
#import "SpotlightView.h"

@interface Spotlight : NSWindowController
{
	SpotlightView *spotlightView;
	NSView *view;
}
@property(retain) NSView *view;

+ (Spotlight *) sharedSpotlight;
- (void) displaySpotlightAt: (NSPoint) point;
- (void) hideSpotlight;

@end