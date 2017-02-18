#import <Foundation/Foundation.h>

@interface LibraryCard : NSManagedObject
{
}

@property(nonatomic, retain)	NSString	*authentication1;
@property(nonatomic, retain)	NSString	*authentication2;
@property(nonatomic, retain)	NSString	*authentication3;
@property(nonatomic, retain)	NSNumber	*authenticationOK;
@property(nonatomic, retain)	NSString	*libraryPropertyName;
@property(nonatomic, retain)	NSNumber	*ordering;
@property(nonatomic, retain)	NSString	*name;
@property(nonatomic, retain)	NSNumber	*deleted;
@property(nonatomic, retain)	NSNumber	*enabled;
@property(nonatomic, retain)	NSData		*overrideProperties;
@property(nonatomic, retain)	NSDate		*lastUpdated;

+ (LibraryCard *) libraryCard;

@end