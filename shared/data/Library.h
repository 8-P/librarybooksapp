#import <Foundation/Foundation.h>
#import "Library.h"
@class LibraryDrillDownItem;
#import "LibraryDrillDownItem.h"

@interface Library : NSManagedObject
{
}

@property(nonatomic, retain)	NSString				*identifier;
@property(nonatomic, retain)	NSData					*properties;
@property(nonatomic, retain)	NSString				*path;
@property(nonatomic, retain)	NSString				*name;
@property(nonatomic, retain)	LibraryDrillDownItem	*libraryDrillDownItem;
@property(nonatomic, retain)	NSSet					*locations;
@property(nonatomic, retain)	NSString				*type;
@property(nonatomic, retain)	NSNumber				*beta;

+ (Library *) library;

@end