#import "LoansDetailViewContoller.h"
#import "SharedExtras.h"
#import "GoogleBookSearch.h"
#import "UIColorFactory.h"
#import "UITableViewControllerExtras.h"

@implementation LoansDetailViewContoller

@synthesize loan;

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationController.navigationBar.tintColor = [UIColorFactory themeColor];

	self.title		= loan.title;
	rows			= [[NSMutableArray array] retain];
	
	[self addRowWithText: loan.author];
	[self addRowWithText: [NSString stringWithFormat: @"ISBN: %@", loan.isbn]];
	
	// Format the due date and colour it red for overdues
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle: NSDateFormatterNoStyle];
	[dateFormatter setDateStyle: NSDateFormatterLongStyle];
	NSString *text	= [NSString stringWithFormat: @"Due: %@", [dateFormatter stringFromDate: loan.dueDate]];
	[dateFormatter release];
	UIColor *colour	= (loan.overdue) ? [UIColor redColor] : [UIColor grayColor];
	
	[self addRowWithText: text colour: colour];
}

- (void) addRowWithText: (NSString *) text colour: (UIColor *) colour
{
	if (text == nil || [text length] == 0 || [text hasSubString: @"(null)"]) return;
	if (colour == nil) colour = [UIColor grayColor];

	NSDictionary *row = [NSDictionary dictionaryWithObjectsAndKeys:
		text,	@"Text",
		colour,	@"TextColour",
		nil
	];
	
	[rows addObject: row];
}

- (void) addRowWithText: (NSString *) text
{
	[self addRowWithText: text colour: nil];
}

- (void) dealloc
{
	[loan release];
	[rows release];
	
    [super dealloc];
}

// =============================================================================
#pragma mark -
#pragma mark Table view methods

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
    return 2;
}

// -----------------------------------------------------------------------------
//
// Number of rows.
//
// -----------------------------------------------------------------------------
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
	switch (section)
	{
		case 0: return 1 + [rows count];
		case 1: return 1;
	}
	
	return 0;
}

// -----------------------------------------------------------------------------
//
// Section title.
//
// -----------------------------------------------------------------------------
- (NSString *) tableView: (UITableView *) tableView titleForHeaderInSection: (NSInteger) section
{
	switch (section)
	{
		case 0: return @"Loan";
		case 1: return @"Related Web Links";
	}
	
	return nil;
}

// -----------------------------------------------------------------------------
//
// Table cell.
//
// -----------------------------------------------------------------------------
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: @"DetailsCell"];
    if (cell == nil)
	{
        cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: @"DetailsCell"] autorelease];
    }
	
	if (indexPath.section == 0)
	{
		if (indexPath.row == 0)
		{
			cell.textLabel.lineBreakMode	= UILineBreakModeWordWrap;
			cell.textLabel.numberOfLines	= 0;
			cell.textLabel.text				= loan.title;
			cell.selectionStyle				= UITableViewCellSelectionStyleNone;
			cell.textLabel.font				= [UIFont boldSystemFontOfSize: 17];
		}
		else
		{
			// The info rows have a smaller font
			cell = [tableView dequeueReusableCellWithIdentifier: @"DetailsInfoCell"];
			if (cell == nil)
			{
				cell = [[[UITableViewCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: @"DetailsInfoCell"] autorelease];
				cell.textLabel.font				= [UIFont systemFontOfSize: 14];
				cell.textLabel.numberOfLines	= 0;
				cell.selectionStyle				= UITableViewCellSelectionStyleNone;
			}
			
			NSDictionary *row			= [rows objectAtIndex: indexPath.row - 1];
			cell.textLabel.text			= [row objectForKey: @"Text"];
			cell.textLabel.textColor	= [row objectForKey: @"TextColour"];
		}
	}
	else
	{
		cell.textLabel.text = @"Google Book Search";
		cell.accessoryType	= UITableViewCellAccessoryDetailDisclosureButton;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}

    return cell;
}

// -----------------------------------------------------------------------------
//
// Allow custom height for the title.  Got the code from:
// http://stackoverflow.com/questions/129502/how-do-i-wrap-text-in-a-uitableviewcell-without-a-custom-cell
//
// -----------------------------------------------------------------------------
- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
	if (indexPath.section == 0)
	{
		NSString *cellText;
		UIFont *cellFont;
		if (indexPath.row == 0)
		{
			cellText	= loan.title;
			cellFont	= [UIFont boldSystemFontOfSize: 17];
		}
		else
		{
			NSDictionary *row	= [rows objectAtIndex: indexPath.row - 1];
			cellText			= [row objectForKey: @"Text"];
			cellFont			= [UIFont systemFontOfSize: 14];
		}
			
		CGSize constraintSize	= CGSizeMake([self screenWidth], MAXFLOAT);
		CGSize labelSize		= [cellText sizeWithFont: cellFont constrainedToSize: constraintSize lineBreakMode: UILineBreakModeWordWrap];
		
		return labelSize.height + 20;
	}
	
	return tableView.rowHeight;
}

// -----------------------------------------------------------------------------
//
// Handle clicks on web links.
//
// -----------------------------------------------------------------------------
- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
	// Web links
	if (indexPath.section == 1 && indexPath.row == 0)
	{
		GoogleBookSearch *googleBookSearch = [GoogleBookSearch googleBookSearch];
		URL *queryURL	= [googleBookSearch searchURLForTitle: loan.title author: loan.author isbn: loan.isbn];
		URL *infoURL	= [googleBookSearch infoLinkForURL: queryURL];
		if (infoURL)
		{
			[[UIApplication sharedApplication] openURL: infoURL];
		}
		else
		{
			[self.tableView cellForRowAtIndexPath: indexPath].selected = NO;
		
			UIAlertView *alert	= [[[UIAlertView alloc] init] autorelease];
			alert.message		= [NSString stringWithFormat: @"There is no Google Book Search result for \"%@\"", loan.title];
			alert.delegate		= self;
			
			[alert addButtonWithTitle: @"Cancel"];
			[alert show];
		}
	}
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return YES;
}

@end