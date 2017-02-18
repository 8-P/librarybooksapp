#import <Foundation/Foundation.h>

@interface NSMutableString (NSMutableStringExtras)

- (unsigned int) replaceOccurrencesOfString: (NSString *) target withString: (NSString *) replacement;

@end