#import <Foundation/Foundation.h>
#import "LibraryCard.h"

@interface Hold : NSManagedObject
{
	NSString *queuePositionString;
}

@property(nonatomic, retain)	NSString	*title;
@property(nonatomic, retain)	NSString	*author;
@property(nonatomic, retain)	NSString	*isbn;
@property(nonatomic, retain)	NSNumber	*queuePosition;
@property(nonatomic, retain)	NSString	*queuePositionString;
@property(nonatomic, retain)	NSString	*queueDescription;
@property(nonatomic, retain)	NSString	*pickupAt;
@property(nonatomic, retain)	NSNumber	*readyForPickup;
@property(nonatomic, retain)	id			image;
@property(nonatomic, retain)	NSString	*uriGoogleBookSearch;
@property(nonatomic, retain)	LibraryCard	*libraryCard;
@property(nonatomic, retain)	NSNumber	*dummy;
@property(nonatomic, retain)	NSNumber	*temporary;
@property(nonatomic, retain)	NSDate		*expiryDate;
@property()						BOOL		eBook;

+ (Hold *) hold;
- (void) calculate;
- (NSArray *) notReadyForPickupWords;
- (NSArray *) readyForPickupWords;

@end