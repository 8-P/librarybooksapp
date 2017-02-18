#import <Foundation/Foundation.h>

@interface HTMLElement : NSObject <NSCopying>
{
	NSString		*name;
	NSDictionary	*attributes;
	NSString		*value;
	NSScanner		*scanner;
}

@property(retain)			NSString		*name;
@property(retain)			NSDictionary	*attributes;
@property(retain)			NSString		*value;
@property(retain, readonly) NSScanner		*scanner;

+ (HTMLElement *) element;
- (BOOL) hasAttribute: (NSString *) string;

@end