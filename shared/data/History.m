#import "History.h"
#import "DataStore.h"

@implementation History

@dynamic title, author, isbn, month, image, libraryCardName, libraryIdentifier, lastUpdated;

+ (History *) history
{
	NSManagedObjectContext *context = [DataStore sharedDataStore].managedObjectContext;
	return [NSEntityDescription insertNewObjectForEntityForName: @"History" inManagedObjectContext: context]; 
}

// -----------------------------------------------------------------------------
//
// Create a new history item if one doesn't exist.
//
// -----------------------------------------------------------------------------
+ (History *) historyFromLoan: (Loan *) loan
{
	if ([loan.dummy boolValue])
	{
		// Don't create history items for dummy loans
		return nil;
	}

	// Figure out the month
	NSCalendar *calendar			= [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
	NSDateComponents *components	= [calendar components: NSYearCalendarUnit | NSMonthCalendarUnit fromDate: [NSDate date]];
	[components setDay: 1];
	NSDate *month					= [calendar dateFromComponents: components];
	[calendar release];

	DataStore *dataStore	= [DataStore sharedDataStore];
	History *history		= [dataStore selectHistoryForLoan: loan month: month];
	if (history == nil)
	{
		history						= [History history];
		history.title				= loan.title;
		history.author				= loan.author;
		history.isbn				= loan.isbn;
		history.month				= month;
		history.libraryCardName		= loan.libraryCard.name;
		history.libraryIdentifier	= loan.libraryCard.libraryPropertyName;
	}
	
	// Update the image
	if (history.image == nil)
	{
		history.image = loan.image;
	}
	
	history.lastUpdated = [NSDate date];

	return history;
}

@end
