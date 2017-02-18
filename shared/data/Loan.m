#import "Loan.h"
#import "DataStore.h"
#import "SharedExtras.h"

@implementation Loan

@dynamic title, author, isbn, dueDate, image, uriGoogleBookSearch, libraryCard, dummy, temporary, timesRenewed, eBook;
@dynamic overdue;

+ (Loan *) loan
{
	NSManagedObjectContext *context = [DataStore sharedDataStore].managedObjectContext;
	return [NSEntityDescription insertNewObjectForEntityForName: @"Loan" inManagedObjectContext: context]; 
}

- (BOOL) overdue
{
	return [self daysUntilDue] <= 0;
}

- (int) daysUntilDue
{
//	NSTimeInterval interval = [[self.dueDate dateWithoutTime] timeIntervalSinceDate: [NSDate today]];
	return [[self.dueDate dateWithoutTime] timeIntervalSinceDate: [NSDate today]] / 86400;
}

- (NSString *) description
{
	return [NSString stringWithFormat: @"Loan: title [%@], author [%@], isbn [%@], renewed [%d], dueDate [%@%@]",
		self.title, self.author, self.isbn, [self.timesRenewed intValue], self.dueDate, [self.dueDate isToday] ? @" TODAY" : @""];
}

@end