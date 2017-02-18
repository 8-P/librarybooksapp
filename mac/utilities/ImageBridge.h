#import <Cocoa/Cocoa.h>

@interface ImageBridge : NSObject
{
	NSImage *image;
}

@property(readonly) NSImage *image;

+ (ImageBridge *) imageWithData: (NSData *) data;
- (id) initWithData: (NSData *) data;
- (NSData *) thumbnailWithSize: (CGSize) size;
- (NSRect) calculateThumbnailRect: (NSSize) targetSize originalSize: (NSSize) originalSize;

@end