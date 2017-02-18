#import <Cocoa/Cocoa.h>
#import <Sparkle/Sparkle.h>

@interface Sparkle : NSObject <SUVersionComparison>
{

}

- (NSNumber *) numberForVersionString: (NSString *) string;

@end