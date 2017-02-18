#import <Foundation/Foundation.h>

@interface StatusReporter : NSObject
{
}

+ (void) reportStatus: (NSInteger) status libraryIdentifier: (NSString *) identifier;
+ (void) delayStatusReportsForADay;

@end