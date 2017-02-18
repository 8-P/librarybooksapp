#import "AnimatedRefreshButton.h"

@implementation AnimatedRefreshButton

@synthesize button;

- (id) init
{
	self = [super init];

//	UIImageView *view					= [[UIImageView alloc] initWithImage: [UIImage imageNamed: @"EmptyRefreshButton.png"]];
	UIView *view						= [[UIView alloc] initWithFrame: CGRectMake(0, 0, 35, 30)];
	UIActivityIndicatorViewStyle style	= (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? UIActivityIndicatorViewStyleGray : UIActivityIndicatorViewStyleWhite;
	activityIndicator					= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: style];
	activityIndicator.autoresizingMask	= UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin
											| UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
	activityIndicator.center			= view.center;
	[view addSubview: activityIndicator];
	
	button = [[UIBarButtonItem alloc] initWithCustomView: view];
	[view release];
	
	return self;
}

- (void) startAnimating
{
	[activityIndicator startAnimating];
}

- (void) stopAnimating
{
	[activityIndicator stopAnimating];
}

- (void) dealloc
{
	[activityIndicator release];
	[super dealloc];
}

@end