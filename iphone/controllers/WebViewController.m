#import "WebViewController.h"
#import "SharedExtras.h"

@implementation WebViewController

@dynamic url;

- (void) dealloc
{
	[zoomButton release];
    [super dealloc];
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void) loadView
{
	UIWebView *webView					= [[UIWebView alloc] initWithFrame: CGRectZero];
	webView.multipleTouchEnabled		= YES;
	webView.scalesPageToFit				= NO;
	self.view							= webView;
	[webView release];
	
	zoomButton = [[UIBarButtonItem alloc] initWithImage: [UIImage imageNamed: @"ZoomOut.png"]
		style: UIBarButtonItemStyleBordered target: self action: @selector(toggleScalesPagesToFit:)];
	self.navigationItem.rightBarButtonItem = zoomButton;
}

- (void) viewDidUnload
{
	self.view = nil;
    [super viewDidUnload];
}

- (void) toggleScalesPagesToFit: (id) sender
{
	UIWebView *webView = (UIWebView *) self.view;
	if (webView.scalesPageToFit)
	{
		webView.scalesPageToFit = NO;
		zoomButton.image		= [UIImage imageNamed: @"ZoomOut.png"];
	}
	else
	{
		webView.scalesPageToFit = YES;
		zoomButton.image		= [UIImage imageNamed: @"ZoomIn.png"];
	}
	
	[webView reload];
}

// -----------------------------------------------------------------------------
//
// Allow the screen to be rotated in all directions except upside down.
//
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return YES;
}

- (void) setUrl: (URL *) url
{
	if (url == nil) return;

	if ([[url method] isEqualToString: @"POST"])
	{
		NSString *filePath = [[[NSFileManager defaultManager] temporaryDirectory] stringByAppendingPathComponent: @"redirect.html"];
		NSString *html = [url redirectPageForPostURL];
		[html writeToFile: filePath atomically: YES encoding: NSUTF8StringEncoding error: nil];
		url = [URL fileURLWithPath: filePath];
	}

	[(UIWebView *) self.view loadRequest: [NSURLRequest requestWithURL: url]];
}

@end