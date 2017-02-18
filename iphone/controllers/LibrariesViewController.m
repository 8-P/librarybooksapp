// =============================================================================
//
// Show the list of supported libraries for the user to select.
//
// =============================================================================

#import "LibrariesViewController.h"
#import "DataStore.h"
#import "Location.h"
#import "FindingTableViewCell.h"
#import "MoreLibrariesViewController.h"
#import "UIColorFactory.h"

@implementation LibrariesViewController

@synthesize libraryCard;

- (void) dealloc
{
	[libraryProperties release];
	[libraryCard release];
	[locationManager release];
    [super dealloc];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationController.navigationBar.tintColor = [UIColorFactory themeColor];
	
	self.navigationItem.title = @"Library";
	libraryProperties = [[LibraryProperties libraryProperties] retain];
	
	// Setup core location.  Note that we only need a quick and rough location
	// so we set it to the poorest accuracy
	locationManager					= [[CLLocationManager alloc] init];
	locationManager.delegate		= self;
	locationManager.distanceFilter	= 1000;
	locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
	//locationManager.purpose				= @"To find nearby libraries.";  // 3.2 feature
	
	if (locationManager.locationServicesEnabled)
	{
		[locationManager startUpdatingLocation];
	}
}

// -----------------------------------------------------------------------------
//
// Delegate method when current location found.
//
// Upadte the list view with a list of libraries nearby the location.
//
// -----------------------------------------------------------------------------
- (void) locationManager: (CLLocationManager *) manager didUpdateToLocation: (CLLocation *) newLocation fromLocation: (CLLocation *) oldLocation
{
	NSLog(@"Found location [lat %0.5f] [lon %0.5f]", newLocation.coordinate.latitude, newLocation.coordinate.longitude); 

	// Stop core location updates because we only need one result
	[manager stopUpdatingLocation];
	
//	// This is just to animate the change
//	[nearbyLocations release];
//	nearbyLocations = [[NSArray alloc] init];
//	[self.tableView deleteRowsAtIndexPaths: [NSArray arrayWithObject: [NSIndexPath indexPathForRow: 0 inSection: 0]] withRowAnimation: UITableViewRowAnimationFade];
	
	// Update the list
	[nearbyLocations release];
	nearbyLocations = [[[DataStore sharedDataStore] locationsNearLocation: newLocation] retain];
	[self.tableView reloadData];
}

- (void) locationManager: (CLLocationManager *) manager didFailWithError: (NSError *) error
{
	if ([error code] == kCLErrorDenied)
	{
		[manager stopUpdatingLocation];
		[nearbyLocations release];
		nearbyLocations = [[NSArray alloc] init];
		
		[self.tableView reloadData];
	}
}

// =============================================================================
#pragma mark -
#pragma mark Table view methods

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
	if (nearbyLocations)
	{
		return [nearbyLocations count] + 1;
	}
	else
	{
		// Give room for the "Finding" and "More Libraries" buttons
		return 2;
	}
}

// -----------------------------------------------------------------------------
//
// Notes:
//		* Displays "Finding" cell when acquiring location via GPS.
//
// -----------------------------------------------------------------------------
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
	if (indexPath.row == [tableView numberOfRowsInSection: indexPath.section] - 1)
	{
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"MoreCell"];
		if (cell == nil)
		{
			cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: @"MoreCell"] autorelease];
		}
		
		cell.textLabel.text = @"More Libraries";
		cell.accessoryType	= UITableViewCellAccessoryDisclosureIndicator;
		
		return cell;
	}
	else
	{
		if (nearbyLocations == nil)
		{
			FindingTableViewCell *cell = (FindingTableViewCell *) [tableView dequeueReusableCellWithIdentifier: @"FindingCell"];
			if (cell == nil)
			{
				cell = [[[FindingTableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: @"FindingCell"] autorelease];
			}
			
			return cell;
		}
		else
		{
			UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"LocationCell"];
			if (cell == nil)
			{
				cell							= [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: @"LocationCell"] autorelease];
				cell.textLabel.font				= [UIFont boldSystemFontOfSize: 17];
				cell.textLabel.numberOfLines	= 0;
			}
			
			Location *location			= [nearbyLocations objectAtIndex: indexPath.row];
			NSDictionary *properties	= [libraryProperties libraryPropertiesForIdentifier: location.identifier];
			cell.textLabel.text			= [properties objectForKey: @"Name"];
			
			if ([location.library.beta boolValue])
			{
				UIImageView *view = [[[UIImageView alloc] initWithImage: [UIImage imageNamed: @"BetaTag.png"]] autorelease];
				cell.accessoryView = view;
			}
			else
			{
				cell.accessoryView = nil;
			}
			
			return cell;
		}
	}
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
	if (indexPath.row == [tableView numberOfRowsInSection: indexPath.section] - 1)
	{
		// Display the library selector
		MoreLibrariesViewController *viewController = [[MoreLibrariesViewController alloc] initWithStyle: UITableViewStyleGrouped];
		viewController.libraryCard = libraryCard;
		[self.navigationController pushViewController: viewController animated: YES];
		[viewController release];
	}
	else
	{
		if (nearbyLocations)
		{
			Location *location					= [nearbyLocations objectAtIndex: indexPath.row];
			libraryCard.libraryPropertyName		= location.identifier;
			
			[self.navigationController popViewControllerAnimated: YES];
		}
	}
}

// -----------------------------------------------------------------------------
//
// Allow custom height for the title.
//
// -----------------------------------------------------------------------------
- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
	if (nearbyLocations && indexPath.row < [nearbyLocations count])
	{
		Location *location			= [nearbyLocations objectAtIndex: indexPath.row];
		NSString *cellText			= location.library.name;
		UIFont *cellFont			= [UIFont boldSystemFontOfSize: 17];
			
		CGSize constraintSize	= CGSizeMake((location.library.beta) ? 239.0 : 280.0, MAXFLOAT);
		CGSize labelSize		= [cellText sizeWithFont: cellFont constrainedToSize: constraintSize lineBreakMode: UILineBreakModeWordWrap];
		
		return labelSize.height + 20;
	}
	
	return tableView.rowHeight;
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return YES;
}

@end