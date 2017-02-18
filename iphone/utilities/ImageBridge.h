#import <UIKit/UIKit.h>

@interface ImageBridge : NSObject
{
	UIImage *image;
}

@property(readonly) UIImage *image;

+ (ImageBridge *) imageWithData: (NSData *) data;
- (id) initWithData: (NSData *) data;
- (NSData *) thumbnailWithSize: (CGSize) size;

@end