#import "SectionView.h"

@implementation SectionView

@dynamic title;

#define MARGIN_LEFT		22
#define MARGIN_RIGHT	10

- (id) initWithFrame: (NSRect) frame
{
    self = [super initWithFrame: frame];
    if (self)
	{
		[self setAutoresizingMask: NSViewWidthSizable];
    }
    return self;
}

- (void) dealloc
{
	[titleLabel release];
	[super dealloc];
}

- (void) drawRect: (NSRect) frame
{
	if (titleLabel == nil)
	{
		titleLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(MARGIN_LEFT, 0, frame.size.width - MARGIN_LEFT - MARGIN_RIGHT, frame.size.height - 2)];
		[titleLabel setEditable:				NO];
		[titleLabel setBordered:				NO];
		[titleLabel setSelectable:				NO];
		[titleLabel setFont:					[NSFont systemFontOfSize: 9]];
		[titleLabel setAlignment:				NSCenterTextAlignment];
		[titleLabel setBackgroundColor:			[NSColor clearColor]];
		[titleLabel setTextColor:				[NSColor disabledControlTextColor]];
		[titleLabel setAutoresizesSubviews:		YES];
		[titleLabel setAutoresizingMask:		NSViewWidthSizable];
		
		[self addSubview: titleLabel];
	}
	
	[titleLabel setStringValue: title];
}

- (void) setTitle: (NSString *) value
{
	[title release];
 	title = [value retain];
}

@end