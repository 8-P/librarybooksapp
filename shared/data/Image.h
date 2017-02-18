#import <Foundation/Foundation.h>
#import "Loan.h"
#import "Hold.h"

@interface Image : NSManagedObject
{
}

@property(nonatomic, retain)	NSData		*thumbnail;
@property(nonatomic, retain)	NSString	*uri;

+ (Image *) image;
+ (Image *) imageForLoan: (Loan *) loan;
+ (Image *) imageForHold: (Hold *) hold;
+ (Image *) imageForTitle: (NSString *) title author: (NSString *) author isbn: (NSString *) isbn;

- (void) downloadImage;

@end