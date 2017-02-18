#import <Cocoa/Cocoa.h>

@interface MenuIconView : NSView <NSMenuDelegate>
{
	NSTextField	*_textField;
	NSImageView	*_bookView;
	NSImageView	*_bookmarkView;
	BOOL		_menuVisible;
	NSString	*_stringValue;
	NSStatusItem *_statusItem;
	NSString *_bookColour;
	NSString *_bookmarkColour;
	BOOL		compactDisplayMode;
	BOOL		_textChanged;
}

@property (retain, nonatomic) NSStatusItem *statusItem;
@property (retain, nonatomic) NSString *stringValue;
@property (retain, nonatomic) NSString *bookmarkColour;
@property (retain, nonatomic) NSString *bookColour;
@property (readonly) BOOL compactDisplayMode;

+ (MenuIconView *) menuIconView;
- (void) highlight: (BOOL) enable;

@end