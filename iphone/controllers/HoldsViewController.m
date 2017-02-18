#import "HoldsViewController.h"
#import "Hold.h"
#import "LoansTableViewCell.h"
#import "CountTableViewCell.h"
#import "UIViewExtras.h"
#import "HoldsDetailViewController.h"
#import "OPAC.h"
#import "WebViewController.h"
#import "UIColorFactory.h"

@implementation HoldsViewController

- (void) dealloc
{
	[dataStore release];
	[fetchedResultsController release];
    [super dealloc];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationController.navigationBar.tintColor = [UIColorFactory themeColor];
	
	dataStore = [[DataStore sharedDataStore] retain];

	refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemRefresh
		target: self action: @selector(reload:)];
	animatedRefreshButton = [[AnimatedRefreshButton alloc] init];
	self.navigationItem.rightBarButtonItem = refreshButton;
	
	// Setup the update manager.  Note that we call resendNotifications to force
	// the notifications to be resent because each tab bar view is created on demand
	// and it may have missed a notification
	updateManager = [[UpdateManager sharedUpdateManager] retain];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updateBegin:)
		name: @"UpdateBegin" object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(updateEnd:)
		name: @"UpdateEnd" object: nil];
	[updateManager resendNotifications];

	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reloadTable:)
		name: @"TablesNeedReloading" object: nil];
	
	[self reloadTable: nil];
}

- (void) viewWillAppear: (BOOL) animated
{
	[super viewWillAppear: animated];
	[self reloadTable: nil];
	
	// Restore the previous scroll position
	NSUserDefaults *defaults		= [NSUserDefaults standardUserDefaults];
	CGFloat offset					= [defaults floatForKey: @"ScrollPositionHoldsView"];
	CGFloat maxOffset				= self.tableView.contentSize.height - [self.tableView frame].size.height;
	if (maxOffset < 0) maxOffset	= 0;
	if (offset > maxOffset) offset  = maxOffset;
	self.tableView.contentOffset	= CGPointMake(0, offset);
}

- (void) viewWillDisappear: (BOOL) animated
{
	[super viewWillDisappear: animated];
	
	// Save the current scroll postion
	NSUserDefaults *defaults	= [NSUserDefaults standardUserDefaults];
	CGFloat offset				= self.tableView.contentOffset.y;
	[defaults setFloat: offset forKey: @"ScrollPositionHoldsView"];
}

// -----------------------------------------------------------------------------
//
// Release any properties that are loaded in viewDidLoad or can be recreated
// lazily.
//
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
	[fetchedResultsController release];
	fetchedResultsController = nil;
}

- (void) reload: (id) sender
{
	[updateManager update];
}

- (void) updateBegin: (id) sender
{
	[animatedRefreshButton startAnimating];
	self.navigationItem.rightBarButtonItem = animatedRefreshButton.button;
}

- (void) updateEnd: (id) sender
{
	[animatedRefreshButton stopAnimating];
	self.navigationItem.rightBarButtonItem = refreshButton;
}

- (void) reloadTable: (id) sender
{
	if (fetchedResultsController == nil)
	{
		fetchedResultsController			= [[dataStore fetchHolds] retain];
		fetchedResultsController.delegate	= self;
	}
	
	NSError *error;
//	[fetchedResultsController.managedObjectContext lock];
	if ([fetchedResultsController performFetch: &error] == NO)
	{
		[dataStore logError: error withSummary: @"failed to reloadTable in HoldsViewController"];
	}
	
	[self.tableView reloadData];
//	[fetchedResultsController.managedObjectContext unlock];
	
	// Overlay the "No Holds message"
	if ([dataStore countHolds] == 0)
	{
		[[self.view superview] addOverlayView: noHoldsView];
		
		BOOL authenticationOK				= [dataStore authenticationOKForAllLibraryCards];
		noHoldsViewMainLabel.text			= (authenticationOK == YES) ? @"No Holds" : @"Invalid Login";
		BOOL showBottomHints				= [[dataStore selectLibraryCards] count] == 0 || authenticationOK == NO;
		BOOL showTopHints					= !showBottomHints;
		noHoldsViewBottomHintArrow.hidden	= showTopHints;
		noHoldsViewBottomHintLabel.hidden	= showTopHints;
		noHoldsViewTopHintArrow.hidden		= showBottomHints;
		noHoldsViewTopHintLabel.hidden		= showBottomHints;
	}
	else
	{
		[[self.view superview] removeOverlayView: noHoldsView];
	}
}

// =============================================================================
#pragma mark -
#pragma mark NSFetchedResultsController delegates
 
- (void) controllerDidChangeContent: (NSFetchedResultsController *) controller
{
	[self reloadTable: nil];
}

// =============================================================================
#pragma mark -
#pragma mark Table view methods

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
//	[fetchedResultsController.managedObjectContext lock];
	NSInteger count = [[fetchedResultsController sections] count];
//	[fetchedResultsController.managedObjectContext unlock];
	
	return count;
}

- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
//	[fetchedResultsController.managedObjectContext lock];
	NSInteger count = [[[fetchedResultsController sections] objectAtIndex: section] numberOfObjects];
//	[fetchedResultsController.managedObjectContext unlock];
	
	return count;
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
//	[fetchedResultsController.managedObjectContext lock];
	NSString *name = [[[fetchedResultsController sections] objectAtIndex: section] name];
	name = [dataStore libraryCardNameForOrdering: [name intValue]];
//	[fetchedResultsController.managedObjectContext unlock];
	
	return name;
}

- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
//	[fetchedResultsController.managedObjectContext lock];
	NSInteger count = [[[fetchedResultsController sections] objectAtIndex: indexPath.section] numberOfObjects];
	Hold *hold		= (indexPath.row < count) ? [fetchedResultsController objectAtIndexPath: indexPath] : nil;
//	[fetchedResultsController.managedObjectContext unlock];

	// Display the count on the last row
	if ([hold.dummy boolValue])
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"CountCell"];
		if (cell == nil)
		{
			cell = [[[CountTableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: @"CountCell"] autorelease];
		}
		
		if ([hold.libraryCard.authenticationOK boolValue] == NO)
		{
			cell.textLabel.text = @"Invalid Login";
			cell.accessoryType	= UITableViewCellAccessoryNone;
		}
		else
		{
			int count			= indexPath.row;
			cell.textLabel.text = (count == 1) ? @"1 Hold" : [NSString stringWithFormat: @"%d Holds", count];
			
			OPAC *opac			= [OPAC opacForLibraryCard: hold.libraryCard];
			cell.accessoryType	= ([opac respondsToSelector: @selector(myAccountURL)])
									? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
		}
		
		return cell;
	}
	
	LoansTableViewCell *cell;
	if ([hold.readyForPickup boolValue])
	{
		// Display a green cell when ready
		cell = (LoansTableViewCell *) [tableView dequeueReusableCellWithIdentifier: @"HoldReadyCell"];
		if (cell == nil)
		{
			cell = [[[LoansTableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: @"HoldReadyCell"] autorelease];
			cell.backgroundImageView.image = [UIImage imageNamed: @"HoldReadyBackground.png"];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.positionTextLabel.textColor = [UIColor whiteColor];
		}
		
		cell.positionTextLabel.text = @"★";
	}
	else
	{
		// Display a normal white cell when not ready.
		cell = (LoansTableViewCell *) [tableView dequeueReusableCellWithIdentifier: @"HoldCell"];
		if (cell == nil)
		{
			cell = [[[LoansTableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: @"HoldCell"] autorelease];
			cell.positionTextLabel.font = [UIFont boldSystemFontOfSize: 20];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		}
		
		int queuePosition = [hold.queuePosition intValue];
		if (queuePosition > -1)
		{
			cell.positionTextLabel.text = [NSString stringWithFormat: @"%d", queuePosition];
		}
		else
		{
			// We sometimes don't know the queue position and the value gets
			// set to -1.  Display an empty label in this case
			cell.positionTextLabel.text = @"";
		}
	}
	
	cell.longDivider			= YES;
	cell.textLabel.text			= hold.title;
	cell.detailTextLabel.text	= hold.queueDescription;
	
	// Image
	Image *image = hold.image;
	if (image.thumbnail)
	{
		cell.imageView.image	= [UIImage imageWithData: image.thumbnail];
	}
	else
	{
		// TODO: display placeholder image, have one for a CD vs Book
		cell.imageView.image	= [UIImage imageNamed: @"ImagePlaceholder.png"];
	}
	
	return cell;
}

// -----------------------------------------------------------------------------
//
// Handle row select.
//
// -----------------------------------------------------------------------------
- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
//	[fetchedResultsController.managedObjectContext lock];
	HoldsDetailViewController *viewController	= [[HoldsDetailViewController alloc] initWithStyle: UITableViewStyleGrouped];
	viewController.hold							= [fetchedResultsController objectAtIndexPath: indexPath];
//	[fetchedResultsController.managedObjectContext unlock];

	if ([viewController.hold.dummy boolValue] == NO)
	{
		[self.navigationController pushViewController: viewController animated: YES];
	}
	[viewController release];
}

// -----------------------------------------------------------------------------
//
// Open the library My Account page when the disclosure button is tapped.
//
// -----------------------------------------------------------------------------
- (void) tableView: (UITableView *) tableView accessoryButtonTappedForRowWithIndexPath: (NSIndexPath *) indexPath
{
//	[fetchedResultsController.managedObjectContext lock];
	
	Hold *hold = [fetchedResultsController objectAtIndexPath: indexPath];
	
	OPAC *opac = [OPAC opacForLibraryCard: hold.libraryCard];
	if ([opac respondsToSelector: @selector(myAccountURL)] == NO) return;
	
	URL *url = [opac performSelector: @selector(myAccountURL)];
	if (url == nil) return;
	
	WebViewController *viewController	= [[WebViewController alloc] init];
	viewController.title				= hold.libraryCard.name;
	viewController.url					= url;
	
//	[fetchedResultsController.managedObjectContext unlock];
	
	[self.navigationController pushViewController: viewController animated: YES];
	[viewController release];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return YES;
}

@end