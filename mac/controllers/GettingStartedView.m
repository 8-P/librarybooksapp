#import "GettingStartedView.h"

@implementation GettingStartedView

@synthesize simleImageView;

- (id) init
{
    self = [super init];
	
	if ([NSBundle loadNibNamed: @"GettingStarted" owner: self] == NO)
	{
		NSLog(@"Failed to load GettingStarted.xib");
		return nil;
	}
	
	[self.simleImageView.image setTemplate: YES];
	
    return self;
}

@end