#import <Foundation/Foundation.h>

@interface SingleLibrary : NSObject
{
	BOOL			enabled;
	NSString		*name;
	NSString		*identifier;
	NSUInteger		themeColour;
}

@property			BOOL		enabled;
@property(retain)	NSString	*name;
@property(retain)	NSString	*identifier;
@property			NSUInteger	themeColour;

- (BOOL) isIdentifierEnabled: (NSString *) compareIdentifier;
+ (SingleLibrary *) sharedSingleLibrary;

@end