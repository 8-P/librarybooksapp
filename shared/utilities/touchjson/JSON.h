#import <Foundation/Foundation.h>

@interface JSON : NSObject
{
}

+ (id) toJson: (NSString *) string;
+ (NSString *) toString: (id) json;

@end