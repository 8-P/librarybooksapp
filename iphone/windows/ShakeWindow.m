#import "ShakeWindow.h"

@implementation ShakeWindow

- (void) motionEnded: (UIEventSubtype) motion withEvent: (UIEvent *) event
{
    if ( event.subtype == UIEventSubtypeMotionShake )
    {
// Disable shake event
//		[[NSNotificationCenter defaultCenter] postNotificationName: @"ShakeEvent" object:self];
    }

	if ([super respondsToSelector: @selector(motionEnded:withEvent:)])
	{
		[super motionEnded: motion withEvent: event];
	}
}

@end