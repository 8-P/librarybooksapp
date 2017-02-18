#import "HoldsView.h"
#import "NSAttributedStringExtension.h"
#import "NSColorExtras.h"
#import "SharedExtras.h"

@implementation HoldsView

// =============================================================================
#pragma mark -
#pragma mark Constants

#define MARGIN_LEFT		18
#define MARGIN_RIGHT	18
#define MARGIN_BOTTOM	5
#define HEIGHT_MIN		20

#define QUEUE_X			MARGIN_LEFT
#define QUEUE_WIDTH		40

#define DOT_X			(QUEUE_X + QUEUE_WIDTH + 10)
#define DOT_WIDTH		16
#define DOT_HEIGHT		16

#define TITLE_X			(DOT_X + DOT_WIDTH + 4)

// =============================================================================
#pragma mark -

@synthesize queuePosition, title, author, pickupAt, queueDescription, readyForPickup, expiryDate;

- (id) initWithFrame: (NSRect) frame
{
    self = [super initWithFrame: frame];
    if (self)
	{
		[self setAutoresizingMask: NSViewWidthSizable];
		[self setAutoresizingMask: NSViewHeightSizable];
    }
    return self;
}

- (void) dealloc
{
	[queuePositionLabel release];
	[titleLabel release];
	[queuePosition release];
	[title release];
	[author release];
	[super dealloc];
}

- (void) drawRect: (NSRect) frame
{
	// Day
	if (queuePositionLabel == nil)
	{
		queuePositionLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(QUEUE_X, 0, QUEUE_WIDTH, frame.size.height)];
		[queuePositionLabel setEditable:			NO];
		[queuePositionLabel setBordered:			NO];
		[queuePositionLabel setSelectable:			NO];
		[queuePositionLabel setFont:				[NSFont boldSystemFontOfSize: 16]];
		[queuePositionLabel setAlignment:			NSCenterTextAlignment];
		[queuePositionLabel setBackgroundColor:		[NSColor clearColor]];
		[queuePositionLabel setTextColor:			[NSColor disabledControlTextColor]];
		[queuePositionLabel setAutoresizesSubviews:	YES];
		[queuePositionLabel setAutoresizingMask:	NSViewMinYMargin];
		[self addSubview: queuePositionLabel];
	}
	[queuePositionLabel setStringValue: queuePosition];

	// Dot
	if (dot == nil)
	{
		dot = [[NSImageView alloc] initWithFrame: NSMakeRect(DOT_X, 0, DOT_WIDTH, frame.size.height - 3)];
		[dot setImageScaling:			NSImageScaleNone];
		[dot setAutoresizesSubviews:	YES];
		[dot setAutoresizingMask:		NSViewMinYMargin];
		[dot setImageAlignment:			NSImageAlignTop];
		
		[self addSubview: dot];
	}
	
	if (readyForPickup)
	{
		[dot setImage: [NSImage imageNamed: @"DotGreen.png"]];
		[dot setAlphaValue: 1];
	}
	else
	{
		[dot setImage: [NSImage imageNamed: @"DotGrey.png"]];
		[dot setAlphaValue: 0.4];
	}

	// Title
	if (titleLabel == nil)
	{
		titleLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(TITLE_X, 0, frame.size.width - TITLE_X - MARGIN_RIGHT, frame.size.height)];
		[titleLabel setEditable:			NO];
		[titleLabel setBordered:			NO];
		[titleLabel setSelectable:			NO];
		[titleLabel setFont:				[NSFont menuFontOfSize: 14]];
		[titleLabel setBackgroundColor:		[NSColor clearColor]];
		[titleLabel setAutoresizingMask:	NSViewWidthSizable];
		[titleLabel setAutoresizesSubviews: YES];
		[titleLabel setAutoresizingMask:	NSViewHeightSizable | NSViewMaxYMargin | NSViewMinYMargin];
		
		[self addSubview: titleLabel];
	}
	
	NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] init] autorelease];
	[string appendAttributedString: [NSAttributedString normalMenuString: title]];
	
	if (author && [author length] > 0)
	{
		[string appendAttributedString: [NSAttributedString normalMenuString:				@"\n"]];
		[string appendAttributedString: [NSAttributedString tinyItalicDisabledMenuString:	@"by  "]];
		[string appendAttributedString: [NSAttributedString tinyDisabledMenuString:			[author uppercaseString]]];
	}
	
	if (queueDescription && [queueDescription length] > 0)
	{
		[string appendAttributedString: [NSAttributedString normalMenuString:				@"\n"]];
		[string appendAttributedString: [NSAttributedString tinyItalicDisabledMenuString:	@"status  "]];
		[string appendAttributedString: [NSAttributedString tinyDisabledMenuString:			[queueDescription uppercaseString]]];
	}
	
	if (pickupAt && [pickupAt length] > 0)
	{
		[string appendAttributedString: [NSAttributedString normalMenuString:				@"\n"]];
		[string appendAttributedString: [NSAttributedString tinyItalicDisabledMenuString:	@"pickup  "]];
		[string appendAttributedString: [NSAttributedString tinyDisabledMenuString:			[pickupAt uppercaseString]]];
	}

	if (expiryDate)
	{
		NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
		if (abs([expiryDate timeIntervalSinceNow]) < 86400 * 365/2)
		{
			[dateFormatter setDateFormat: @"EEE d MMM"];
		}
		else
		{
			[dateFormatter setDateFormat: @"EEE d MMM yyyy"];
		}
	
		[string appendAttributedString: [NSAttributedString normalMenuString:				@"\n"]];
		[string appendAttributedString: [NSAttributedString tinyItalicDisabledMenuString:	@"pickup by  "]];
		[string appendAttributedString: [NSAttributedString tinyDisabledMenuString:			[[dateFormatter stringFromDate: expiryDate] uppercaseString]]];
	}
	
	[titleLabel setAttributedStringValue: string];
	
	[self adjustHeightForTextField: titleLabel];
}

- (void) setHold: (Hold *) hold
{
	if ([hold.readyForPickup boolValue])
	{
		self.queuePosition = @"★";
	}
	else if ([hold.queuePosition intValue] > 0)
	{
		self.queuePosition = [NSString stringWithFormat: @"%d", [hold.queuePosition intValue]];
	}
	else
	{
		self.queuePosition = @"";
	}

	self.title				= hold.title;
	self.author				= hold.author;
	self.pickupAt			= hold.pickupAt;
	self.queueDescription	= hold.queueDescription;
	self.readyForPickup		= [hold.readyForPickup boolValue];
	self.expiryDate			= hold.expiryDate;

//	[self setNeedsDisplay: YES];
	[self drawRect: [self frame]];
}

// =============================================================================
#pragma mark -
#pragma mark Private functions

// -----------------------------------------------------------------------------
//
// Resize the view to fit the text field.
//
//		* http://www.sheepsystems.com/sourceCode/sourceStringGeometrics.html
//		* http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/TextLayout/Tasks/StringHeight.html
//
// -----------------------------------------------------------------------------
- (void) adjustHeightForTextField: (NSTextField *) textLabel
{
	NSAttributedString *attributedString	= [textLabel attributedStringValue];
	CGFloat widthConstraint					= [textLabel frame].size.width;
	CGFloat heightConstraint				= FLT_MAX;
	NSSize sizeConstraint					= NSMakeSize(widthConstraint, heightConstraint);
	
	NSTextContainer *textContainer	= [[NSTextContainer alloc] initWithContainerSize: sizeConstraint];
	NSTextStorage *textStorage		= [[NSTextStorage alloc] initWithAttributedString: attributedString];
	NSLayoutManager *layoutManager	= [[NSLayoutManager alloc] init];
	
	[layoutManager addTextContainer: textContainer];
	[textStorage addLayoutManager: layoutManager];

	// Force update
	[layoutManager glyphRangeForTextContainer: textContainer];
	
	NSSize sizeThatFits = [layoutManager usedRectForTextContainer: textContainer].size;
	
	[textStorage release];
	[textContainer release];
	[layoutManager release];
	
	CGFloat height = MAX(HEIGHT_MIN, sizeThatFits.height + MARGIN_BOTTOM);
	[self setFrameSize: NSMakeSize([self frame].size.width, height)];
}

@end