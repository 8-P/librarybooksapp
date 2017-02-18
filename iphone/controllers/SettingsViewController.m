#import "SettingsViewController.h"
#import "LibraryCardViewController.h"
#import "DataStore.h"
#import "LibraryCard.h"
#import "LibraryProperties.h"
#import "ListViewController.h"
#import "SwitchTableViewCell.h"
#import "Notifications.h"
#import "UIColorFactory.h"
#import "SingleLibrary.h"
#import "DebugReporter.h"

typedef enum {Upwards, Downwards} Direction;

// -----------------------------------------------------------------------------

@implementation SettingsViewController

// Set up the grouped table style.
- (id) initWithCoder: (NSCoder *) coder
{
	[super initWithCoder: coder];
	
	// Use the grouped style
    if (self = [self initWithStyle: UITableViewStyleGrouped])
	{
    }
	
    return self;
}

- (void) dealloc
{
	[dataStore release];
	[fetchedResultsController release];
	[defaults release];
	[settings release];
	[alertView release];
	[updateOperation release];
	[libraryCardToEdit release];
    [super dealloc];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationController.navigationBar.tintColor = [UIColorFactory themeColor];
	
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.tableView.allowsSelectionDuringEditing = YES;
	
	defaults = [[NSUserDefaults standardUserDefaults] retain];
	settings = [[Settings sharedSettings] retain];
	
	dataStore = [[DataStore sharedDataStore] retain];
	fetchedResultsController = [[dataStore fetchLibraryCards] retain];
	fetchedResultsController.delegate = self;
	
	NSError *error;
	if ([fetchedResultsController performFetch: &error])
	{
		// Handler error // TODO
	}
}

// -----------------------------------------------------------------------------
//
// Make sure the table view is updated after returning from editing/adding
// a library card.
//
// Note that we need to reload the table view in both viewDidAppear: and
// viewWillAppear: because in some cases it won't refresh properly.  Example:
//		* When library card list is empty.
//		* You add a new card.
//		* The row just has an empty string, even hough reloadData has been
//		  called in viewWillAppear:
//		* Calling it in viewDidAppear: works but you see the update happen on
//		  screen which is ugly
//
// -----------------------------------------------------------------------------
- (void) viewDidAppear: (BOOL) animated
{
	[self.tableView reloadData];
}

// =============================================================================
#pragma mark -
#pragma mark Fetched results controller delegates

- (void) controller: (NSFetchedResultsController *) controller didChangeObject: (id) object
	atIndexPath: (NSIndexPath *) indexPath forChangeType: (NSFetchedResultsChangeType) type
    newIndexPath: (NSIndexPath *) newIndexPath
{
	switch (type)
	{
		case NSFetchedResultsChangeDelete:
		{
			[self.tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject:indexPath] withRowAnimation: UITableViewRowAnimationBottom];
			break;
		}
		case NSFetchedResultsChangeInsert:
		{
			[self.tableView insertRowsAtIndexPaths: [NSArray arrayWithObject:newIndexPath] withRowAnimation: UITableViewCellEditingStyleNone];
			break;
		}
	}
}

- (void) controllerDidChangeContent: (NSFetchedResultsController *) controller
{
	if (!self.tableView.editing) [self.tableView reloadData];
}

// =============================================================================
#pragma mark -
#pragma mark Table view methods

// -----------------------------------------------------------------------------
//
// Number of sections
//
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
    return 5;
}

// -----------------------------------------------------------------------------
//
// Number of rows
//
// -----------------------------------------------------------------------------
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
	switch (section)
	{
		case 0: return [self countLibraryCards] + 1;
		case 1: return 3;
		case 2: return 1;
		case 3: return 1;
		case 4: return 2;
	}
	
	return 0;
}

// -----------------------------------------------------------------------------
//
// Section title
//
// -----------------------------------------------------------------------------
- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
	switch (section)
	{
		case 0: return @"Library Cards";
		case 1: return @"Alerts";
		case 2: return @"Appearance";
		case 3: return @"Syncing";
	}
	
	return nil;
}

- (NSString *) tableView: (UITableView *) tableView titleForFooterInSection: (NSInteger) section
{
	switch (section)
	{
		case 1: return @"Notifications are available in iOS 4 and later.";
		case 2: return @"Hint: updates will be quicker if you turn off Book Covers.";
		case 4:
		{
			SingleLibrary *singledLibrary = [SingleLibrary sharedSingleLibrary];
			NSString *singledLibraryName = (singledLibrary.enabled) ? [NSString stringWithFormat: @"%@\n", singledLibrary.name] : @"";
			return [NSString stringWithFormat: @"\n%@Library Books %@",
				singledLibraryName,
				[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"]];
		}
	}
	
	return nil;
}

// -----------------------------------------------------------------------------
//
// Cell content.
//
// -----------------------------------------------------------------------------
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
	if (indexPath.section == 0)
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"SettingsCell"];
		if (cell == nil)
		{
			cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleValue1 reuseIdentifier: @"SettingsCell"] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}

		if (indexPath.row < [self countLibraryCards])
		{
			LibraryCard *libraryCard	= [fetchedResultsController objectAtIndexPath: indexPath];
			cell.textLabel.text			= libraryCard.name;
			cell.detailTextLabel.text	= ([libraryCard.enabled boolValue]) ? @"" : @"Off";
		}
		else
		{
			cell.textLabel.text			= @"Add Library Card...";
			cell.detailTextLabel.text	= @"";
		}
		
		return cell;
	}
	else if (indexPath.section == 1)
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"SettingsCell2"];
		if (cell == nil)
		{
			cell						= [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleValue1 reuseIdentifier: @"SettingsCell2"] autorelease];
			cell.accessoryType			= UITableViewCellAccessoryDisclosureIndicator;
			cell.editingAccessoryType	= UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle			= UITableViewCellSelectionStyleBlue;
		}
		
		if (indexPath.row == 0)
		{
			cell.textLabel.text = @"Overdue Warning";
			cell.detailTextLabel.text = settings.overdueAlertTitle;
		}
		else if (indexPath.row == 1)
		{
			SwitchTableViewCell *cell	= [SwitchTableViewCell cellForTableView: tableView];
			cell.textLabel.text			= @"App Badge";
			cell.switchView.on			= settings.appBadge;
			[cell.switchView addTarget: self action: @selector(appBadgeChanged:) forControlEvents: UIControlEventValueChanged];
			return cell;
		}
		else
		{
			SwitchTableViewCell *cell	= [SwitchTableViewCell cellForTableView: tableView];
			cell.textLabel.text			= @"Overdue Notifications";
			cell.switchView.on			= settings.overdueNotification;
			[cell.switchView addTarget: self action: @selector(overdueNotificationChanged:) forControlEvents: UIControlEventValueChanged];
			return cell;
		}

		return cell;
	}
	else if (indexPath.section == 2)
	{
		SwitchTableViewCell *cell	= [SwitchTableViewCell cellForTableView: tableView];
		cell.textLabel.text			= @"Book Covers";
		cell.switchView.on			= settings.bookCovers;
		[cell.switchView addTarget: self action: @selector(bookCoversChanged:) forControlEvents: UIControlEventValueChanged];
		
		return cell;
	}
	else if (indexPath.section == 3)
	{
		SwitchTableViewCell *cell	= [SwitchTableViewCell cellForTableView: tableView];
		cell.textLabel.text			= @"Sync on Start";
		cell.switchView.on			= settings.autoUpdate;
		[cell.switchView addTarget: self action: @selector(autoUpdateChanged:) forControlEvents: UIControlEventValueChanged];
		
		return cell;
	}
	else if (indexPath.section == 4)
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"SettingsCell5"];
		if (cell == nil)
		{
			cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: @"SettingsCell5"] autorelease];
			cell.accessoryType			= UITableViewCellAccessoryDisclosureIndicator;
			cell.editingAccessoryType	= UITableViewCellAccessoryDisclosureIndicator;
			cell.selectionStyle			= UITableViewCellSelectionStyleBlue;
		}
		
		if (indexPath.row == 0)
		{
			cell.textLabel.text			= @"Legal";
			cell.accessoryType			= UITableViewCellAccessoryDisclosureIndicator;
			cell.editingAccessoryType	= UITableViewCellAccessoryDisclosureIndicator;
		}
		else if (indexPath.row == 1)
		{
			cell.textLabel.text			= @"Send Debug Report";
			cell.accessoryType			= UITableViewCellAccessoryDetailDisclosureButton;
			cell.editingAccessoryType	= UITableViewCellAccessoryDetailDisclosureButton;
		}
		
		return cell;
	}
	
	return nil;
}

// -----------------------------------------------------------------------------
//
// Cell selection
//
// -----------------------------------------------------------------------------
- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
	if (indexPath.section == 0)
	{
		LibraryProperties *libraryProperties = [LibraryProperties libraryProperties];
		[libraryProperties quickUpdate];
		
		[libraryCardToEdit release];
		if (indexPath.section == 0 && indexPath.row < [self countLibraryCards])
		{
			// Preload the view if editing an existing library
			libraryCardToEdit = [[fetchedResultsController objectAtIndexPath: indexPath] retain];
		}
		else
		{
			libraryCardToEdit = nil;
		}
		
		[alertView release];
		if (checkedForUpdate == NO)
		{
			// Display a progress indicator and download the new libraries file
			
			alertView			= [[UIAlertView alloc] init];
			alertView.title		= @"Updating";
			alertView.message	= @"Updating libraries\n\n\n";
			alertView.delegate	= self;
			
			UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
			CGRect frame		= activityView.frame;
			frame.origin.x	   += 139 - frame.size.width / 2;
			frame.origin.y	   += 75;
			activityView.frame	= frame;
			[alertView addSubview: activityView];
			[activityView startAnimating];
			[activityView release];
			
			[alertView addButtonWithTitle: @"Cancel"];
			[alertView show];
			
			// Start the update thread
			[updateOperation release];
			updateOperation = [[NSInvocationOperation alloc] initWithTarget: self 
				selector: @selector(updateLibrariesList) object: nil];
			NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
			[operationQueue addOperation: updateOperation];
			[operationQueue release];
		}
		else
		{
			alertView = nil;
			[self displayLibraryCardEditor];
		}
		
		// Don't display this alert until another application restart
		checkedForUpdate = YES;
	}
	else if (indexPath.section == 1)
	{
		if (indexPath.row == 0)
		{
			ListViewController *viewController	= [[ListViewController alloc] initWithStyle: UITableViewStyleGrouped];
			viewController.propertyList			= settings.overdueAlertProperties;
			viewController.navigationItem.title = [tableView cellForRowAtIndexPath: indexPath].textLabel.text;
			
			[self.navigationController pushViewController: viewController animated: YES];
			[viewController release];
		}
		else if (indexPath.row == 1)
		{
			// No selection for app badge switch
		}
		else if (indexPath.row == 2)
		{
			// No selection for overdue notification switch
		}
	}
	else if (indexPath.section == 2)
	{
	}
	else if (indexPath.section == 3)
	{
	}
	else if (indexPath.section == 4)
	{
		if (indexPath.row == 0)
		{
			// Display Legal stuff
			UIViewController *viewController	= [[UIViewController alloc] init];
			UIWebView *webView					= [[UIWebView alloc] initWithFrame: CGRectZero]; 
			viewController.view					= webView;
			viewController.title				= [tableView cellForRowAtIndexPath: indexPath].textLabel.text;
			
			[webView loadRequest: [NSURLRequest requestWithURL: [NSURL fileURLWithPath:
				[[NSBundle mainBundle] pathForResource: @"Legal" ofType: @"html"] isDirectory:NO]]];
			
			[self.navigationController pushViewController: viewController animated: YES];
			[webView release];
			[viewController release];
		}
		else if (indexPath.row == 1)
		{
			// Debug report
			DebugReporter *reporter = [DebugReporter sharedDebugReporter];
			[reporter presentDebugReporterForView: self];
			
			[tableView deselectRowAtIndexPath: indexPath animated: YES];
		}
	}
}

- (void) tableView: (UITableView *) tableView accessoryButtonTappedForRowWithIndexPath: (NSIndexPath *) indexPath
{
	if (indexPath.section == 4 && indexPath.row == 1)
	{
		// Debug report
		DebugReporter *reporter = [DebugReporter sharedDebugReporter];
		[reporter presentDebugReporterForView: self];
		
		[tableView deselectRowAtIndexPath: indexPath animated: YES];
	}
}

// =============================================================================
#pragma mark -
#pragma mark Libraries list updating

// -----------------------------------------------------------------------------
//
// Wrapper for the LibraryProperties' checkForUpdate to display the
// network activity indicator when the check is happening.
//
// -----------------------------------------------------------------------------
- (BOOL) checkForUpdate
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	LibraryProperties *libraryProperties = [LibraryProperties libraryProperties];
	NSDictionary *updateInfo = [libraryProperties checkForUpdate];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	return updateInfo != nil;
}

// -----------------------------------------------------------------------------
//
// Handle the cancel operation.  We don't actually stop the updating but just
// dismiss the alert dialog.
//
// -----------------------------------------------------------------------------
- (void) alertView: (UIAlertView *) alertView didDismissWithButtonIndex: (NSInteger) buttonIndex
{
	// Only send the debug if the "Send" button was selected
	if (buttonIndex == 0)
	{
		[updateOperation cancel];
		[self displayLibraryCardEditor];
	}
}

// -----------------------------------------------------------------------------
//
// NSInvocationOperation thread for doing the updating.
//
// -----------------------------------------------------------------------------
- (void) updateLibrariesList
{
	if ([self checkForUpdate])
	{
		LibraryProperties *libraryProperties = [LibraryProperties libraryProperties];
		[libraryProperties clearCache];
	
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		[libraryProperties update];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
	
	if ([updateOperation isCancelled] == NO)
	{
		[self performSelectorOnMainThread: @selector(displayLibraryCardEditor) withObject: nil waitUntilDone: NO];
	}
}

// -----------------------------------------------------------------------------
//
// Display the library card editor window.
//
// -----------------------------------------------------------------------------
- (void) displayLibraryCardEditor
{
	[alertView dismissWithClickedButtonIndex: 1 animated: NO];

	LibraryCardViewController *viewController = [[LibraryCardViewController alloc] initWithStyle: UITableViewStyleGrouped];
	viewController.libraryCard = libraryCardToEdit;
	
	// Display the library card editor.  Note that call presentModalViewController:
	// so that the editor slides in from the bottom of the screen
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController: viewController];
	[self presentModalViewController: navigationController animated: YES];

	[viewController release];
	[navigationController release];
}

// =============================================================================
#pragma mark -
#pragma mark Editing

// -----------------------------------------------------------------------------
//
// Reorder the library card rows.
//
// The logic is as follows:
//		* Move the row to the new location.
//		* Depending on the direction that the row is being moved, shift the
//		* the other rows upwards or downwards to make room.
//		* Only the rows between the source and destination rows need to be
//		  moved.
//
// -----------------------------------------------------------------------------
- (void) tableView: (UITableView *) tableView moveRowAtIndexPath: (NSIndexPath *) sourceIndexPath toIndexPath: (NSIndexPath *) destinationIndexPath
{
	Direction direction = (sourceIndexPath.row < destinationIndexPath.row) ? Downwards : Upwards;
	int ordering		= 0;

	for (LibraryCard *libraryCard in [dataStore selectAllLibraryCards])
	{
		if (ordering == sourceIndexPath.row)
		{
			libraryCard.ordering = [NSNumber numberWithInt: destinationIndexPath.row];
		}
		else
		{
			if (direction == Downwards)
			{
				// The row is being move downwards so shift the other rows up
				if (sourceIndexPath.row < ordering && ordering <= destinationIndexPath.row)
				{
					libraryCard.ordering =  [NSNumber numberWithInt: ordering - 1];
				}
			}
			else
			{
				// The row is being move upwards so shift the other rows down
				if (destinationIndexPath.row <= ordering && ordering < sourceIndexPath.row)
				{
					libraryCard.ordering =  [NSNumber numberWithInt: ordering + 1];
				}
			}
		}
		
		ordering++;
	}
	
	// Debug
	NSLog(@"Re-ordered library cards:");
	for (LibraryCard *libraryCard in [dataStore selectAllLibraryCards])
	{
		NSLog(@"\t%d - %@", [libraryCard.ordering intValue], libraryCard.name);
	}
	
	[dataStore save];
	[dataStore sendReloadNotification];
}

// -----------------------------------------------------------------------------
//
// Constraint the reordering of the libraries to the top section.
//
// -----------------------------------------------------------------------------
- (NSIndexPath *) tableView: (UITableView *) tableView targetIndexPathForMoveFromRowAtIndexPath: (NSIndexPath *) sourceIndexPath 
	toProposedIndexPath: (NSIndexPath *) proposedDestinationIndexPath
{
	NSUInteger lastRow = [tableView numberOfRowsInSection: 0] - 2;
	if (proposedDestinationIndexPath.section == 0 && proposedDestinationIndexPath.row < lastRow)
	{
		return proposedDestinationIndexPath;
	}
	else
	{
		return [NSIndexPath indexPathForRow: lastRow inSection: 0];
	}
}

// -----------------------------------------------------------------------------
//
// Allow the library card items to be reordered.
//
// -----------------------------------------------------------------------------
- (BOOL) tableView: (UITableView *) tableView canMoveRowAtIndexPath: (NSIndexPath *) indexPath
{
	return (indexPath.section == 0 && indexPath.row < [tableView numberOfRowsInSection: indexPath.section] - 1);
}

// -----------------------------------------------------------------------------
//
// Put a delete and insert button in front of the library card items.
//
// -----------------------------------------------------------------------------
- (UITableViewCellEditingStyle) tableView:(UITableView *) tableView editingStyleForRowAtIndexPath: (NSIndexPath *) indexPath
{
	if (indexPath.section == 0)
	{
		if (indexPath.row < [self countLibraryCards])
		{
			return UITableViewCellEditingStyleDelete;
		}
		else
		{
			return UITableViewCellEditingStyleInsert;
		}
	}
	
	return UITableViewCellEditingStyleNone;
}

// -----------------------------------------------------------------------------
//
// Handle delete and insert actions.
//
// Assumptions:
//		* Editing actions only work on the library list so we don't have any
//		  checking of the indexPath.
//
// -----------------------------------------------------------------------------
- (void) tableView: (UITableView *) tableView commitEditingStyle: (UITableViewCellEditingStyle) editingStyle 
	forRowAtIndexPath: (NSIndexPath *) indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		// Delete the library card
		LibraryCard *libraryCard = [fetchedResultsController objectAtIndexPath: indexPath];
		[dataStore deleteLibraryCard: libraryCard];
		
		[dataStore save];
		[tableView reloadData];
	}
	else if (editingStyle == UITableViewCellEditingStyleInsert)
	{
		[self tableView: tableView didSelectRowAtIndexPath: indexPath];
	}
}

- (int) countLibraryCards
{
	int count = 0;
	
	NSArray *sections = [fetchedResultsController sections];
	if ([sections count])
	{
		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex: 0];
		count = [sectionInfo numberOfObjects];
	}
	
	return count;
	

	//	id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex: 0];
	//	return sectionInfo.numberOfObjects;
}

- (void) bookCoversChanged: (UISwitch *) switchControl
{
	settings.bookCovers = switchControl.on;
}

- (void) autoUpdateChanged: (UISwitch *) switchControl
{
	settings.autoUpdate = switchControl.on;
}

- (void) appBadgeChanged: (UISwitch *) switchControl
{
	settings.appBadge = switchControl.on;
	
	// Update the notifications
	Notifications *notifications = [Notifications notifications];
	[notifications update];
}

- (void) overdueNotificationChanged: (UISwitch *) switchControl
{
	settings.overdueNotification = switchControl.on;
	
	// Update the notifications
	Notifications *notifications = [Notifications notifications];
	[notifications update];
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return YES;
}

@end