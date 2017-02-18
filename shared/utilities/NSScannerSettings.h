#import <Foundation/Foundation.h>
#import "OrderedDictionary.h"

@interface NSScannerSettings : NSObject
{
	NSArray				*loanColumns;
	NSArray				*holdColumns;
	OrderedDictionary	*loanColumnsDictionary;
	OrderedDictionary	*holdColumnsDictionary;
	int					minColumns;
	BOOL				columnCountMustMatch;
	BOOL				ignoreTableHeaderCells;
	BOOL				ignoreHTMLScripts;
}

@property(retain)	NSArray				*loanColumns;
@property(retain)	NSArray				*holdColumns;
@property(retain)	OrderedDictionary	*loanColumnsDictionary;
@property(retain)	OrderedDictionary	*holdColumnsDictionary;
@property			int					minColumns;
@property			BOOL				columnCountMustMatch;
@property			BOOL				ignoreTableHeaderCells;
@property			BOOL				ignoreHTMLScripts;

- (void) reset;
+ (NSScannerSettings *) sharedSettings;

@end