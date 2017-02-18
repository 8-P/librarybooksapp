#import "ModalAlert.h"

@implementation ModalAlert
{
	UIAlertView *alertView;
	NSInteger buttonIndex;
}

@synthesize alertView;

- (id) init
{
	self				= [super init];
	alertView			= [[UIAlertView alloc] init];
	alertView.delegate	= self;
	
	return self;
}

- (void) dealloc
{
	[alertView release];
	[super dealloc];
}

- (NSInteger) showModal
{
	buttonIndex = -1;
	
	[alertView performSelectorOnMainThread: @selector(show) withObject: nil waitUntilDone: YES];
	
	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	while ([alertView isVisible] && buttonIndex == -1)
	{
		NSDate *date = [NSDate dateWithTimeIntervalSinceNow: 1];
		[runLoop runUntilDate: date];
	}
	
	return buttonIndex;
}

- (void) alertView: (UIAlertView *) alertView clickedButtonAtIndex: (NSInteger) buttonIndexClicked
{
	buttonIndex = buttonIndexClicked;
}

@end