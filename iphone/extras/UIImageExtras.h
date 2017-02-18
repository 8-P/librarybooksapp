#import <Foundation/Foundation.h>

@interface UIImage (UIImageExtras)

- (UIImage *) imageByScalingAndCroppingToSize: (CGSize) targetSize;

@end