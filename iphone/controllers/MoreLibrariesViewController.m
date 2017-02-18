// =============================================================================
//
// This is the library drill down list.
//
// =============================================================================

#import "MoreLibrariesViewController.h"
#import "RegexKitLite.h"
#import "SharedExtras.h"
#import "LibraryDrillDownItem.h"
#import "UIColorFactory.h"
#import "UITableViewControllerExtras.h"

@implementation MoreLibrariesViewController

@synthesize libraryCard, currentPath;

- (void) dealloc
{
	[fetchedResultsController release];
	[libraryCard release];
	[dataStore release];
	[currentPath release];
    [super dealloc];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationController.navigationBar.tintColor = [UIColorFactory themeColor];
	
	dataStore = [[DataStore sharedDataStore] retain];
	
	// Set the default title
	if (self.navigationItem.title == nil) self.navigationItem.title	= @"Library";
	
	// Set the default path
	if (currentPath == nil) currentPath = @"/";
	
	[fetchedResultsController release];
	fetchedResultsController = [[dataStore fetchLibraryDrillDownItemForPath: currentPath] retain];

	NSError *error;
	if ([fetchedResultsController performFetch: &error])
	{
		// Handler error // TODO
	}
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
    NSArray *sections = [fetchedResultsController sections];
    NSUInteger count = 0;
    if ([sections count])
	{
        id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
        count = [sectionInfo numberOfObjects];
    }
    
	return count;

//	id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex: section];
//	return sectionInfo.numberOfObjects;
}

// -----------------------------------------------------------------------------
//
// Customize the appearance of table view cells.
//
// -----------------------------------------------------------------------------
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MoreLibrariesCell"];
	if (cell == nil)
	{
		cell							= [[[UITableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: @"MoreLibrariesCell"] autorelease];
		cell.textLabel.font				= [UIFont boldSystemFontOfSize: 17];
		cell.textLabel.numberOfLines	= 0;
	}

	LibraryDrillDownItem *item	= [fetchedResultsController objectAtIndexPath: indexPath];
	cell.textLabel.text	= item.name;
	
	if ([item.isFolder boolValue])
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	else
	{
		if ([item.library.beta boolValue])
		{
			UIImageView *view = [[[UIImageView alloc] initWithImage: [UIImage imageNamed: @"BetaTag.png"]] autorelease];
			cell.accessoryView = view;
		}
		else
		{
			cell.accessoryView = nil;
		}
		
		// Draw a checkbox next to the selected library
		if ([libraryCard.libraryPropertyName isEqualToString: item.library.identifier])
		{
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		else
		{
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
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
	LibraryDrillDownItem *item = [fetchedResultsController objectAtIndexPath: indexPath];
	
	if ([item.isFolder boolValue])
	{
		// Drill down
		MoreLibrariesViewController *viewController = [[MoreLibrariesViewController alloc] initWithStyle: UITableViewStyleGrouped];
		viewController.libraryCard					= libraryCard;
		viewController.currentPath					= [item.path stringByAppendingPathComponent: item.name];
		viewController.navigationItem.title			= item.name;
		
		[self.navigationController pushViewController: viewController animated: YES];
		[viewController release];
	}
	else
	{
		// Select the library and jump back to the library settings view
		libraryCard.libraryPropertyName = item.library.identifier;
		[self.navigationController popToRootViewControllerAnimated: YES];
	}
}

// -----------------------------------------------------------------------------
//
// Allow custom height for the title.  Got the code from:
// http://stackoverflow.com/questions/129502/how-do-i-wrap-text-in-a-uitableviewcell-without-a-custom-cell
//
// -----------------------------------------------------------------------------
- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
	LibraryDrillDownItem *item	= [fetchedResultsController objectAtIndexPath: indexPath];
	NSString *cellText			= item.name;
	UIFont *cellFont			= [UIFont boldSystemFontOfSize: 17];

	int width = [self screenWidth];
	if (item.library.beta) width -= 41;

	CGSize constraintSize	= CGSizeMake(width, MAXFLOAT);
	CGSize labelSize		= [cellText sizeWithFont: cellFont constrainedToSize: constraintSize lineBreakMode: UILineBreakModeWordWrap];
	
	return labelSize.height + 20;
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return YES;
}

@end