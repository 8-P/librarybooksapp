#import "MigrationViewController.h"
#import "DataStore.h"
#import "LBTouchAppDelegate.h"

@implementation MigrationViewController

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void) viewDidAppear: (BOOL) animated
{
    [super viewDidAppear: animated];
	
	alertView			= [[UIAlertView alloc] init];
	alertView.title		= @"Upgrading Database";
	alertView.message	= @"This may take few moments";
	alertView.delegate	= self;
	
	UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
	CGRect frame		= activityView.frame;
	frame.origin.x	   += 139 - frame.size.width / 2;
	frame.origin.y	   += 75;
	activityView.frame	= frame;
	[alertView addSubview: activityView];
	[activityView startAnimating];
	[activityView release];
	
//	[alertView addButtonWithTitle: @"Cancel"];
	[alertView show];
	
	// Start the update thread
	[updateOperation release];
	updateOperation = [[NSInvocationOperation alloc] initWithTarget: self 
		selector: @selector(migrate) object: nil];
	NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
	[operationQueue addOperation: updateOperation];
	[operationQueue release];
}

// -----------------------------------------------------------------------------
//
// NSInvocationOperation thread for doing the updating.
//
// -----------------------------------------------------------------------------
- (void) migrate
{
	[[DataStore sharedDataStore] persistentStoreCoordinator];
	
	[self performSelectorOnMainThread: @selector(loadMainApplication) withObject: nil waitUntilDone: NO];
}

- (void) loadMainApplication
{
	[alertView dismissWithClickedButtonIndex: 1 animated: NO];
	
	[self.view removeFromSuperview];
	
	LBTouchAppDelegate *appDelegate = (LBTouchAppDelegate *) [UIApplication sharedApplication].delegate;
	[appDelegate loadMainApplication];
}

// -----------------------------------------------------------------------------
//
// Only allow rotation on the iPad.
//
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end