#import "HistoryViewController.h"
#import "UIViewExtras.h"
#import "HistoryDetailViewController.h"
#import "HistoryTableViewCell.h"
#import "Settings.h"
#import "UIColorFactory.h"

@implementation HistoryViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationController.navigationBar.tintColor = [UIColorFactory themeColor];

	dataStore			= [[DataStore sharedDataStore] retain];
	dateFormatter		= [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat: @"MMM YYYY"];
	
	indexDateFormatter	= [[NSDateFormatter alloc] init];
	[indexDateFormatter setDateFormat: @"MMM"];
}

- (void) viewWillAppear: (BOOL) animated
{
	[super viewWillAppear: animated];
	[self reloadTable: nil];
	
	// Restore the previous scroll position
	NSUserDefaults *defaults		= [NSUserDefaults standardUserDefaults];
	CGFloat offset					= [defaults floatForKey: @"ScrollPositionHistoryView"];
	CGFloat maxOffset				= self.tableView.contentSize.height - [self.tableView frame].size.height;
	if (maxOffset < 0) maxOffset	= 0;
	if (offset > maxOffset) offset	= maxOffset;
	self.tableView.contentOffset	= CGPointMake(0, offset);
}

- (void) viewWillDisappear: (BOOL) animated
{
	[super viewWillDisappear: animated];
	
	// Save the current scroll postion
	NSUserDefaults *defaults	= [NSUserDefaults standardUserDefaults];
	CGFloat offset = self.tableView.contentOffset.y;
	[defaults setFloat: offset forKey: @"ScrollPositionHistoryView"];
}

- (void) dealloc
{
    [super dealloc];
	[months release];
	[fetchedResultsController release];
	[dataStore release];
	[dateFormatter release];
	[indexDateFormatter release];
}

- (void) reloadTable: (id) sender
{
	[months release];
	months = [[dataStore selectHistoryMonths] retain];
	
	if (fetchedResultsController == nil)
	{
		fetchedResultsController			= [[dataStore fetchHistory] retain];
		fetchedResultsController.delegate	= self;
	}
	
	NSError *error;
//	[fetchedResultsController.managedObjectContext lock];
	if ([fetchedResultsController performFetch: &error] == NO)
	{
		[dataStore logError: error withSummary: @"failed to reloadTable in HistoryViewController"];
	}

	[self.tableView reloadData];
//	[fetchedResultsController.managedObjectContext unlock];
	
	// Overlay the "No History message"
	if ([dataStore countHistory] == 0)	[[self.view superview] addOverlayView: noHistoryView];
	else								[[self.view superview] removeOverlayView: noHistoryView];
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

// -----------------------------------------------------------------------------
//
// Number of rows in section.
//
// -----------------------------------------------------------------------------
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
//	[fetchedResultsController.managedObjectContext lock];
	NSInteger count = [[[fetchedResultsController sections] objectAtIndex: section] numberOfObjects];
//	[fetchedResultsController.managedObjectContext unlock];
	
	return count;
}

- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
	return [dateFormatter stringFromDate: [months objectAtIndex: section]];
	
//	id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex: section];
//	return sectionInfo.name;
}

// -----------------------------------------------------------------------------
//
// For drawing the index along the right hand side.
//
// -----------------------------------------------------------------------------
- (NSArray *) sectionIndexTitlesForTableView: (UITableView *) tableView
{
	// Don't display the index if the list is short.
	if ([fetchedResultsController.sections count] < 2) return nil;

//	return [fetchedResultsController sectionIndexTitles];

	NSMutableArray *titles = [NSMutableArray array];
	for (NSDate *month in months)
	{
		[titles addObject: [indexDateFormatter stringFromDate: month]];
	}
	
	return titles;
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
    HistoryTableViewCell *cell = (HistoryTableViewCell *) [tableView dequeueReusableCellWithIdentifier: @"HistoryCell"];
    if (cell == nil)
	{
        cell = [[[HistoryTableViewCell alloc] initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: @"HistoryCell"] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
//	[fetchedResultsController.managedObjectContext lock];
	History *history			= [fetchedResultsController objectAtIndexPath: indexPath];
//	[fetchedResultsController.managedObjectContext unlock];
	
	cell.textLabel.text			= history.title;
	cell.detailTextLabel.text	= history.author;

	if ([Settings sharedSettings].bookCovers)
	{
		Image *image = history.image;
		if (image.thumbnail)
		{
			cell.imageView.image	= [UIImage imageWithData: image.thumbnail];
		}
		else
		{
			// TODO: display placeholder image, have one for a CD vs Book
			cell.imageView.image	= [UIImage imageNamed: @"ImagePlaceholder.png"];
		}
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
	HistoryDetailViewController *viewController	= [[HistoryDetailViewController alloc] initWithStyle: UITableViewStyleGrouped];
	viewController.history						= [fetchedResultsController objectAtIndexPath: indexPath];
//	[fetchedResultsController.managedObjectContext unlock];
	
	[self.navigationController pushViewController: viewController animated: YES];
	[viewController release];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return YES;
}

@end