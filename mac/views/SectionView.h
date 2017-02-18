#import <Cocoa/Cocoa.h>

@interface SectionView : NSView
{
	NSTextField *titleLabel;
	NSString *title;
}

@property(retain) NSString *title;

@end