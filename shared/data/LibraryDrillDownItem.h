#import <Foundation/Foundation.h>
@class Library;
#import "Library.h"

@interface LibraryDrillDownItem : NSManagedObject
{

}

@property(nonatomic, retain)	NSString	*path;
@property(nonatomic, retain)	NSString	*name;
@property(nonatomic, retain)	NSNumber	*isFolder;
@property(nonatomic, retain)	Library		*library;
@property(nonatomic, retain)	NSString	*type;
@property(nonatomic, retain)	NSString	*imageName;
@property(nonatomic, retain)	NSString	*name2;

+ (LibraryDrillDownItem *) libraryDrillDownItem;

@end