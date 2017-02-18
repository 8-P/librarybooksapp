#import <Foundation/Foundation.h>
#import "LibraryCard.h"

@interface Loan : NSManagedObject
{
}

@property(nonatomic, retain)	NSString	*title;
@property(nonatomic, retain)	NSString	*author;
@property(nonatomic, retain)	NSString	*isbn;
@property(nonatomic, retain)	NSDate		*dueDate;
@property(nonatomic, retain)	id			image;
@property(nonatomic, retain)	NSString	*uriGoogleBookSearch;
@property(nonatomic, retain)	LibraryCard	*libraryCard;
@property(nonatomic, retain)	NSNumber	*dummy;
@property(readonly)				BOOL		overdue;
@property(nonatomic, retain)	NSNumber	*temporary;
@property(nonatomic, retain)	NSNumber	*timesRenewed;
@property()						BOOL		eBook;

+ (Loan *) loan;
- (int) daysUntilDue;

@end