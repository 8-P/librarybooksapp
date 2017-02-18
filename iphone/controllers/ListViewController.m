#import "ListViewController.h"
#import "DataStore.h"
#import "UIColorFactory.h"

@implementation ListViewController

@synthesize propertyList;

- (void) dealloc
{
	[propertyList release];
	[key release];
	[titles release];
	[values release];
	[defaults release];
    [super dealloc];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationController.navigationBar.tintColor = [UIColorFactory themeColor];
	
	titles		= [[propertyList objectForKey: @"Titles"]	retain];
	values		= [[propertyList objectForKey: @"Values"]	retain];
	key			= [[propertyList objectForKey: @"Key"]		retain];
	defaults	= [[NSUserDefaults standardUserDefaults]	retain];
}

// =============================================================================
#pragma mark -
#pragma mark Table view methods

// -----------------------------------------------------------------------------
//
// Number of sections in table view.
//
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
    return 1;
}

// -----------------------------------------------------------------------------
//
// Number of rows in the table view.
//
// -----------------------------------------------------------------------------
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
	return [titles count];
}

// -----------------------------------------------------------------------------
//
// Customize the appearance of table view cells.
//
// -----------------------------------------------------------------------------
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"ListViewCell"];
	if (cell == nil)
	{
		cell = [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: @"ListViewCell"] autorelease];
	}

	cell.textLabel.text	= [titles objectAtIndex: indexPath.row];
	
	// Draw a checkbox next to the selected library
	if ([[values objectAtIndex: indexPath.row] isEqual: [defaults objectForKey: key]])
	{
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}

    return cell;
}

// -----------------------------------------------------------------------------
//
// Handle row selection.
//
// -----------------------------------------------------------------------------
- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
	[defaults setObject: [values objectAtIndex: indexPath.row] forKey: key];
	[defaults synchronize];
	[self.tableView reloadData];
	
	// Send notification so the app badge and alerts are updated
	[[DataStore sharedDataStore] sendReloadNotification];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return YES;
}

@end
