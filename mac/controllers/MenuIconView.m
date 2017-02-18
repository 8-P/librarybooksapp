// =============================================================================
//
// Based on example from http://undefinedvalue.com/2009/07/07/adding-custom-view-nsstatusitem
//
// =============================================================================

#import "MenuIconView.h"
#import "NSImageExtras.h"

@implementation MenuIconView

#define STATUSBAR_HEIGHT 21

#define BOOK_WIDTH 16
#define BOOK_HEIGHT 17

#define BOOKMARK_WIDTH 7
#define BOOKMARK_HEIGHT 8

#define SMALL_BOOKMARK_WIDTH 5
#define SMALL_BOOKMARK_HEIGHT 8

#define PADDING_X 6
#define TEXT_PADDING 1

//@synthesize bookmarkWindow;
@synthesize compactDisplayMode;
@dynamic stringValue, statusItem, bookColour, bookmarkColour;

+ (MenuIconView *) menuIconView
{
	return  [[[MenuIconView alloc] initWithFrame: NSMakeRect(0, 0, BOOK_WIDTH + PADDING_X*2, STATUSBAR_HEIGHT)] autorelease];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		_stringValue = @"";
		_textChanged = YES;
    }
    
    return self;
}

- (void)drawRect: (NSRect) dirtyRect
{
//	[_statusItem setLength: self.frame.size.width];

	if (_bookView == nil)
	{
		_bookView = [[NSImageView alloc] initWithFrame: NSMakeRect(PADDING_X, 3, BOOK_WIDTH, BOOK_HEIGHT)];
//		_bookView = [[NSImageView alloc] initWithFrame: NSMakeRect(PADDING_X, 4, BOOK_WIDTH, BOOK_HEIGHT)];
		[self addSubview: _bookView];
	}
	
	_bookView.image = [self image];
	
	if (_bookmarkView == nil)
	{
//		_bookmarkView = [[NSImageView alloc] initWithFrame: NSMakeRect(PADDING_X + 6, -2, BOOKMARK_WIDTH, BOOKMARK_HEIGHT)];
		_bookmarkView = [[NSImageView alloc] initWithFrame: NSMakeRect(PADDING_X + 6, 12, SMALL_BOOKMARK_WIDTH, SMALL_BOOKMARK_HEIGHT)];
		[self addSubview: _bookmarkView];
	}
	
	_bookmarkView.image = [self bookmarkImage];

	if (_textField == nil)
	{
		_textField = [[NSTextField alloc] initWithFrame: NSZeroRect];
	
		[_textField setEditable:		NO];
		[_textField setBordered:		NO];
		[_textField setSelectable:		NO];
		[_textField setAlignment:		NSLeftTextAlignment];
		[_textField setFont:			[NSFont menuBarFontOfSize: 0]];
//		[_textField setTextColor:		[NSColor whiteColor]];
		[_textField setBackgroundColor: [NSColor clearColor]];
		
		[self addSubview: _textField];
	}
	
	if (_textChanged)
	{
		NSRect rect = self.frame;
		rect.size.height -= 1;
		rect.origin.x = PADDING_X + BOOK_WIDTH + TEXT_PADDING;
		[_textField setFrame: rect];
		
		_textField.stringValue = (_stringValue) ? _stringValue : @"";
		_textField.textColor = [self titleForegroundColor];
		
		_textChanged = NO;
	}
	
//	[self respositionBookmark];
	
	// Draw status bar background, highlighted if menu is showing
	[_statusItem drawStatusBarBackgroundInRect: [self bounds] withHighlight: _menuVisible];
}

/*
- (void) statusBarDidMove:(NSNotification*)notification
{
	[self respositionBookmark];
}*/

- (void) setStatusItem: (NSStatusItem *) statusItem
{
//	NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
//	[center addObserver: self selector: @selector(statusBarDidMove:)
//		name: NSWindowDidMoveNotification object: self.window];
				
	_statusItem = [statusItem retain];
}

/*
- (void) respositionBookmark
{
	[self.bookmarkWindow orderOut: self];

	NSRect iconViewFrame = [self.window frame];
	NSRect bookmarkFrame = self.bookmarkWindow.frame;
	bookmarkFrame.origin.x = NSMinX(iconViewFrame);
	bookmarkFrame.origin.y = NSMinY(iconViewFrame) - bookmarkFrame.size.height;
	
	self.bookmarkWindow.bookmarkImageView.image = [self bookmarkImage];
	
	[self.bookmarkWindow setFrame: bookmarkFrame display: YES];
	
	// Hide the bookmark running in full screen
	NSScreen *screen = [[NSScreen screens] objectAtIndex: 0];
	if (iconViewFrame.origin.y == screen.frame.size.height)
	{
		self.bookmarkWindow.bookmarkImageView.image = nil;
	}
}
*/

- (void) setStringValue: (NSString *) string
{
	if ([_stringValue isEqualToString: string]) return;

	[_stringValue release];
	_stringValue = (string) ? string : @"";
	[_stringValue retain];
	
	_textChanged = YES;
	
//	NSRect titleBounds = [self titleBoundingRect];
//	int newWidth = titleBounds.size.width + (2 * StatusItemViewPaddingWidth);
	
	[self updateStatusItemLength];
	
	[self setNeedsDisplay: YES];
}

- (NSColor *) titleForegroundColor
{
	return (_menuVisible) ? [NSColor whiteColor] : [NSColor blackColor];
}

- (NSDictionary *) titleAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont menuBarFontOfSize: 0],	NSFontAttributeName,
		[self titleForegroundColor],	NSForegroundColorAttributeName,
		nil
	];
}

- (void) setBookColour: (NSString *) bookColour
{
	if ([_bookColour isEqualTo: bookColour]) return;

	[_bookColour release];
	_bookColour = [bookColour retain];
	[self setNeedsDisplay: YES];
}

- (NSString *) bookColour
{
	return _bookColour;
}

- (void) setBookmarkColour: (NSString *) bookmarkColour
{
	if ([_bookmarkColour isEqualTo: bookmarkColour]) return;

	[_bookmarkColour release];
	_bookmarkColour = [bookmarkColour retain];
	[self setNeedsDisplay: YES];
}

- (NSImage *) image
{
	if (_menuVisible)
	{
		return [NSImage imageNamed: @"MenuIconBookWhite"];
	}
	else if ([_bookColour isEqualToString: @"Red"])
	{
		return [NSImage imageNamed: @"MenuIconBookRed"];
	}
	else if ([_bookColour isEqualToString: @"Orange"])
	{
		return [NSImage imageNamed: @"MenuIconBookOrange"];
	}
	else if ([_bookColour isEqualToString: @"Green"])
	{
		return [NSImage imageNamed: @"MenuIconBookGreen"];
	}
	else
	{
		return [NSImage imageNamed: @"MenuIconBookBlack"];
	}
}

- (NSImage *) bookmarkImage
{
	if (_menuVisible)
	{
		return nil;
	}
	
//	if ([_bookmarkColour isEqualToString: @"Green"])
//	{
//		return [NSImage imageNamed: @"MenuIconBookmarkGreen"];
//	}
	if ([_bookmarkColour isEqualToString: @"Black"])
	{
		return [NSImage imageNamed: @"MenuIconBookmarkSmallBlack"];
	}
	else if ([_bookmarkColour isEqualToString: @"White"])
	{
		return [NSImage imageNamed: @"MenuIconBookmarkSmallGrey"];
	}
	else
	{
		return nil;
	}
}

- (NSRect) titleBoundingRect
{
	return [_stringValue boundingRectWithSize: NSMakeSize(1e100, 1e100)
		options: 0 attributes: [self titleAttributes]];
}

- (void) updateStatusItemLength
{
	NSRect titleRect = [self titleBoundingRect];
	[_statusItem setLength: BOOK_WIDTH + TEXT_PADDING + PADDING_X*2 + titleRect.size.width];
}

- (void) highlight: (BOOL) enable
{
	_menuVisible = enable;
	_textChanged = YES;
	[self setNeedsDisplay: YES];
}

- (void) mouseDown: (NSEvent *) event
{
	NSUInteger flags = [event modifierFlags];
	compactDisplayMode = (flags & NSAlternateKeyMask || flags & NSControlKeyMask || flags & NSShiftKeyMask || flags & NSCommandKeyMask);

	[_statusItem popUpStatusItemMenu: _statusItem.menu];
	[self setNeedsDisplay: YES];
}

- (void) rightMouseDown: (NSEvent *) event
{
	[self mouseDown: event];
}

- (void) menuWillOpen: (NSMenu *) menu
{
    _menuVisible = YES;
    [self setNeedsDisplay:YES];
}

- (void) menuDidClose: (NSMenu *) menu
{
    _menuVisible = NO;
    [menu setDelegate: nil];
    [self setNeedsDisplay: YES];
}

@end
