#import <Foundation/Foundation.h>
#import "Image.h"
#import "LibraryCard.h"

@interface History : NSManagedObject
{
}

@property(nonatomic, retain)	NSString	*title;
@property(nonatomic, retain)	NSString	*author;
@property(nonatomic, retain)	NSString	*isbn;
@property(nonatomic, retain)	NSDate		*month;
@property(nonatomic, retain)	Image		*image;
@property(nonatomic, retain)	NSString	*libraryCardName;
@property(nonatomic, retain)	NSString	*libraryIdentifier;
@property(nonatomic, retain)	NSDate		*lastUpdated;

+ (History *) history;
+ (History *) historyFromLoan: (Loan *) loan;

@end