#import "LoansView.h"
#import "NSAttributedStringExtension.h"
#import "NSColorExtras.h"
#import "SharedExtras.h"
#import "Preferences.h"

@implementation LoansView

// =============================================================================
#pragma mark -
#pragma mark Constants

#define MARGIN_LEFT		18
#define MARGIN_RIGHT	18
#define MARGIN_BOTTOM	5
#define HEIGHT_MIN		20

#define WEEKDAY_X		MARGIN_LEFT
#define WEEKDAY_WIDTH	26

#define DAY_X			(WEEKDAY_X + WEEKDAY_WIDTH)
#define DAY_WIDTH		30

#define MONTH_X			(DAY_X + DAY_WIDTH)
#define MONTH_WIDTH		40

#define TODAY_X			WEEKDAY_X - 5
#define TODAY_WIDTH		(MONTH_X + MONTH_WIDTH - WEEKDAY_X)

#define DOT_X			(MONTH_X + MONTH_WIDTH + 10)
#define DOT_WIDTH		16
#define DOT_HEIGHT		16

#define TITLE_X			(DOT_X + DOT_WIDTH + 4)

// =============================================================================
#pragma mark -

@synthesize weekday, day, month, today, title, author, timesRenewed, daysUntilDue;
@dynamic dueDateHidden;

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
	[weekdayLabel release];
	[dayLabel release];
	[monthLabel release];
	[todayLabel release];
	[titleLabel release];
	[weekday release];
	[day release];
	[month release];
	[today release];
	[title release];
	[author release];
	[super dealloc];
}

- (void) drawRect: (NSRect) frame
{
	// Weekday
	if (weekdayLabel == nil)
	{
		weekdayLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(WEEKDAY_X, 0, WEEKDAY_WIDTH, frame.size.height - 6)];
		[weekdayLabel setEditable:				NO];
		[weekdayLabel setBordered:				NO];
		[weekdayLabel setSelectable:			NO];
		[weekdayLabel setFont:					[NSFont systemFontOfSize: 9]];
		[weekdayLabel setAlignment:				NSRightTextAlignment];
		[weekdayLabel setBackgroundColor:		[NSColor clearColor]];
		[weekdayLabel setTextColor:				[NSColor disabledControlTextColor]];
		[weekdayLabel setAutoresizesSubviews:	YES];
		[weekdayLabel setAutoresizingMask:		NSViewMinYMargin];
		[self addSubview: weekdayLabel];
	}
	[weekdayLabel setStringValue: weekday];
	[weekdayLabel setHidden: dueDateHidden];
	
	// Day
	if (dayLabel == nil)
	{
		dayLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(DAY_X, 0, DAY_WIDTH, frame.size.height)];
		[dayLabel setEditable:				NO];
		[dayLabel setBordered:				NO];
		[dayLabel setSelectable:			NO];
		[dayLabel setFont:					[NSFont boldSystemFontOfSize: 16]];
		[dayLabel setAlignment:				NSCenterTextAlignment];
		[dayLabel setBackgroundColor:		[NSColor clearColor]];
		[dayLabel setTextColor:				[NSColor disabledControlTextColor]];
		[dayLabel setAutoresizesSubviews:	YES];
		[dayLabel setAutoresizingMask:		NSViewMinYMargin];
		[self addSubview: dayLabel];
	}
	[dayLabel setStringValue: day];
	[dayLabel setHidden: dueDateHidden];
	
	// Month
	if (monthLabel == nil)
	{
		monthLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(MONTH_X, 0, MONTH_WIDTH, frame.size.height - 6)];
		[monthLabel setEditable:			NO];
		[monthLabel setBordered:			NO];
		[monthLabel setSelectable:			NO];
		[monthLabel setFont:				[NSFont systemFontOfSize: 9]];
		[monthLabel setAlignment:			NSLeftTextAlignment];
		[monthLabel setBackgroundColor:		[NSColor clearColor]];
		[monthLabel setTextColor:			[NSColor disabledControlTextColor]];
		[monthLabel setAutoresizesSubviews: YES];
		[monthLabel setAutoresizingMask:	NSViewMinYMargin];
		
		[self addSubview: monthLabel];
	}
	[monthLabel setStringValue: month];
	[monthLabel setHidden: dueDateHidden];

	// Today/Yesterday
	if (todayLabel == nil)
	{
		todayLabel = [[NSTextField alloc] initWithFrame: NSMakeRect(TODAY_X, 0, TODAY_WIDTH, frame.size.height)];
		[todayLabel setEditable:			NO];
		[todayLabel setBordered:			NO];
		[todayLabel setSelectable:			NO];
		[todayLabel setAlignment:			NSLeftTextAlignment];
		[todayLabel setBackgroundColor:		[NSColor clearColor]];
		[todayLabel setTextColor:			[NSColor disabledControlTextColor]];
		[todayLabel setAutoresizesSubviews: YES];
		[todayLabel setAutoresizingMask:	NSViewMinYMargin];
		
		[self addSubview: todayLabel];
	}
	
	if (today)
	{
		[todayLabel setHidden: dueDateHidden];
		
		NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] init] autorelease];
		[string appendAttributedString: [NSAttributedString boldMenuString: [today substringToIndex: 1]]];
		[string appendAttributedString: [NSAttributedString smallBoldMenuString: [today substringFromIndex: 1]]];
		
		NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
		[style setAlignment: NSCenterTextAlignment];
		[string addAttribute: NSParagraphStyleAttributeName value: style range: NSMakeRange(0, [string length])];
		
		[todayLabel setAttributedStringValue: string];
		
		[weekdayLabel setHidden: YES];
		[dayLabel setHidden: YES];
		[monthLabel setHidden: YES];
	}

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
	
	NSInteger dueSoonWarningDays = [Preferences sharedPreferences].dueSoonWarningDays;
	if (daysUntilDue <= 0)
	{
		[dot setImage: [NSImage imageNamed: @"DotRed.png"]];
		[dot setAlphaValue: 1];
	}
	else if (daysUntilDue <= dueSoonWarningDays)
	{
		[dot setImage: [NSImage imageNamed: @"DotOrange.png"]];
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
		[string appendAttributedString: [NSAttributedString normalMenuString: @"\n"]];
		[string appendAttributedString: [NSAttributedString tinyItalicDisabledMenuString:  @"by  "]];
		[string appendAttributedString: [NSAttributedString tinyDisabledMenuString: [author uppercaseString]]];
	}
	
	if ([timesRenewed length] > 0)
	{
		[string appendAttributedString: [NSAttributedString normalMenuString: @"\n"]];
		[string appendAttributedString: [NSAttributedString tinyItalicDisabledMenuString:  @"renews  "]];
		[string appendAttributedString: [NSAttributedString tinyDisabledMenuString: timesRenewed]];
	}
	
	[titleLabel setAttributedStringValue: string];
	
	[self adjustHeightForTextField: titleLabel];
}

- (void) setLoan: (Loan *) loan
{
	NSDateFormatter *monthDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[monthDateFormatter setDateFormat: @"MMM"];
	NSDateFormatter *weekdayDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[weekdayDateFormatter setDateFormat: @"EEE"];
	NSDateFormatter *dayDateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dayDateFormatter setDateFormat: @"d"];

	self.weekday	= [[weekdayDateFormatter stringFromDate: loan.dueDate] uppercaseString];
	self.day		= [dayDateFormatter stringFromDate: loan.dueDate];
	self.month		= [[monthDateFormatter stringFromDate: loan.dueDate] uppercaseString];

	self.title		= loan.title;
	self.author		= loan.author;
	
	if ([loan.timesRenewed intValue] > 0)
	{
		self.timesRenewed = [NSString stringWithFormat: @"%d", [loan.timesRenewed intValue]];
	}
	else
	{
		self.timesRenewed = @"";
	}

	daysUntilDue = [loan daysUntilDue];
/*	if (daysUntilDue == -1)
	{
		self.today = @"YESTERDAY";
	}
	else if (daysUntilDue == 0)
	{
		self.today = @"TODAY";
	}
	else if (daysUntilDue == 1)
	{
		self.today = @"TOMORROW";
	}
*/

	if ([loan.dueDate isYesterday])
	{
		self.today = @"YESTERDAY";
	}
	else if ([loan.dueDate isToday])
	{
		self.today = @"TODAY";
	}
	else if ([loan.dueDate isTomorrow])
	{
		self.today = @"TOMORROW";
	}

//	[self setNeedsDisplay: YES];
	[self drawRect: [self frame]];
}

- (void) setDueDateHidden: (BOOL) hidden
{
	dueDateHidden = hidden;
	[self setNeedsDisplay: YES];
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