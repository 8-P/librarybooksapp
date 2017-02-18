// =============================================================================
//
// Jacksonville
//
//		* SIRSI6 login.
//		* Loans and holds need custom parsing.
//
// =============================================================================

#import "Jacksonville.h"

@implementation Jacksonville

- (void) parse
{
	NSString *text = [[browser.scanner string] stringWithoutHTML];
	if ([text hasSubString: @"You have no items checked out at this time"] == NO)
	{
		[self parseLoans1];
	}

	[self parseHolds1];
}

// -----------------------------------------------------------------------------
//
// Loans
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format Jacksonville)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	// * "Description" is used by Santa Cruz library for the title/author
	scannerSettings.loanColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"",					@"Item ID",
		@"titleAndAuthor",		@"Item",
		@"parseDueDateCell:",	@"Due Date",
		nil
	];
	
	if (   [scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"charges"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObjects: @"Ascending", @"Descending", nil] delegate: self];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Holds
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format Jacksonville)"];
	NSScanner *scanner = browser.scanner;
	HTMLElement *element;

	[scanner scanPassHead];
	
	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"queuePosition",		@"Position in Queue",
		@"readyForPickup",		@"Available",
		@"titleAndAuthor",		@"Item",
		nil
	];
	
	// Holds (just outstanding or combined holds list)
	if (   [scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"requests"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns ignoreRows: [NSArray arrayWithObjects: @"Ascending", @"Descending", nil] delegate: self];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Parse the due date cell.  The date is generated using JavaScript.
//
//		<script type="text/javascript">
//			<![CDATA[
//			<!--
//				var comma = /,/
//				var DateCharged = "12/8/2012,23:59"
//				var wheresTheComma = DateCharged.search(comma)
//				var DateCheckedOut = DateCharged.slice(0,wheresTheComma)
//				document.write(DateCheckedOut)
//			//-->
//			//]]>
//		</script>
//
// -----------------------------------------------------------------------------
- (NSDictionary *) parseDueDateCell: (NSString *) string
{
	OrderedDictionary *dictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"regex:DateCharged = \"(.*?),", @"dueDate",
		nil
	];

	NSScanner *scanner = [NSScanner scannerWithString: string];
	return [scanner analyseUsingDictionary: dictionary];
}

@end