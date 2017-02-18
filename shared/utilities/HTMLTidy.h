#import <Foundation/Foundation.h>
#import "URL.h"

@interface HTMLTidy : NSObject
{
}

+ (NSString *) tidy: (NSString *) input url: (URL *) url;
+ (NSString *) preTidy: (NSString *) input;

@end