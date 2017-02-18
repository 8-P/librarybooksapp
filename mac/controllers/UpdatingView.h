#import <Cocoa/Cocoa.h>

@interface UpdatingView : NSView
{
	NSTextField	*_textField;
	NSImageView	*_imageView;
}

+ (UpdatingView *) updatingViewWithWidth: (CGFloat) width;

@end