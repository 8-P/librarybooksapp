// =============================================================================
//
// Customised table cell view for the loans.
//
// =============================================================================

#import "LoansTableViewCell.h"
#import "UIColorFactory.h"

@implementation LoansTableViewCell

// -----------------------------------------------------------------------------
#pragma mark -
#pragma mark Constants

static const int kDueDateWidth			= 43;
static const int kImageWidth			= 39;
static const int kHeight				= 43;
static const int kDueDateDayHeight		= 25;
static const int kDueDateMonthHeight	= 18;

// -----------------------------------------------------------------------------
#pragma mark -

@synthesize dueDateDay, dueDateMonth, longDivider, backgroundImageView, positionTextLabel;

- (id) initWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
{
    if (self = [super initWithStyle: UITableViewCellStyleSubtitle reuseIdentifier: reuseIdentifier])
	{
		backgroundImageView				= [[UIImageView alloc] initWithFrame: CGRectZero];
		[self.contentView addSubview: backgroundImageView];

		positionTextLabel				= [[UILabel alloc] initWithFrame: CGRectZero];
		positionTextLabel.textAlignment	= UITextAlignmentCenter;
		positionTextLabel.font			= [UIFont boldSystemFontOfSize: 25];
		positionTextLabel.backgroundColor= [UIColor clearColor];
		[self.contentView addSubview: positionTextLabel];
		
		dueDateDay						= [[UILabel alloc] initWithFrame: CGRectZero];
		dueDateDay.textAlignment		= UITextAlignmentCenter;
		dueDateDay.font					= [UIFont boldSystemFontOfSize: 20];
		dueDateDay.backgroundColor		= [UIColor clearColor];
		[self.contentView addSubview: dueDateDay];

		dueDateMonth					= [[UILabel alloc] initWithFrame: CGRectZero];
		dueDateMonth.textAlignment		= UITextAlignmentCenter;
		dueDateMonth.font				= [UIFont systemFontOfSize: 11];
		dueDateMonth.backgroundColor	= [UIColor clearColor];
		[self.contentView addSubview: dueDateMonth];
		
		verticalRule = [[CALayer layer] retain];
		verticalRule.backgroundColor = [[UIColorFactory tableViewCellSeparatorColor] CGColor];
		[self.contentView.layer insertSublayer: verticalRule atIndex: 0];
		
		horizontalRule = [[CALayer layer] retain];
		horizontalRule.backgroundColor = [[UIColorFactory tableViewCellSeparatorColor] CGColor];
		[self.contentView.layer insertSublayer: horizontalRule atIndex: 0];
		
		// Put a white layer underneath the overdue string to mask the the blue
		// highlight colour when the cell is selected
		CALayer *layer = [CALayer layer];
		layer.frame = CGRectMake(0, 0, kDueDateWidth, self.contentView.bounds.size.height);
		layer.backgroundColor = [[UIColor whiteColor] CGColor];
		[self.contentView.layer insertSublayer: layer atIndex: 0];
		
		settings = [[Settings sharedSettings] retain];
    }

    return self;
}

- (void) dealloc
{
	[backgroundImageView release];
	[dueDateDay release];
	[dueDateMonth release];
	[verticalRule release];
	[horizontalRule release];
	[settings release];
    [super dealloc];
}

- (void) layoutSubviews
{
	[super layoutSubviews];
	
	// Start with a rect that is inset from the content view by 0 pixels on all sides
    CGRect baseRect = CGRectInset(self.contentView.bounds, 0, 0);

	CGRect rect					= baseRect;
	rect.size.width				= kDueDateWidth;
	rect.size.height			= kHeight;
	positionTextLabel.frame		= rect;
	
	// Due date day
	rect						= baseRect;
	rect.size.width				= kDueDateWidth;
	rect.size.height			= kDueDateDayHeight;
	dueDateDay.frame			= rect;
	
	// Due date month
	rect						= baseRect;
	rect.size.width				= kDueDateWidth;
	rect.size.height			= kDueDateMonthHeight;
	rect.origin.y			   += kDueDateDayHeight;
	dueDateMonth.frame			= rect;
	
	rect						= baseRect;
	rect.origin.x			   += kDueDateWidth - 1;
	rect.size.width				= 1;
	rect.size.height			= kHeight;
	verticalRule.frame			= rect;

	rect						= baseRect;
	rect.origin.y				= kHeight;
	rect.size.height			= 1;
	if (longDivider == NO)
	{
		rect.origin.x			= kDueDateWidth - 1;
		rect.size.width		   -= kDueDateWidth - 1;
	}
	horizontalRule.frame		= rect;

	// Overdue background
	rect						= baseRect;
	rect.size.width				= kDueDateWidth;
	rect.size.height			= kHeight + 1;
	backgroundImageView.frame	= rect;

	// Image width
	int imageWidth = (settings.bookCovers) ? kImageWidth : 0;

	// Shift the image over
	rect						= self.imageView.frame;
	rect.origin.x			   += kDueDateWidth;
	rect.size.width				= imageWidth;
	self.imageView.frame		= rect;

	// Shift the text label over
	rect						= self.textLabel.frame;
	rect.origin.x			   += imageWidth;
	rect.size.width			    = self.contentView.frame.size.width - kDueDateWidth - imageWidth - 4;
	self.textLabel.frame		= rect;

	// Shift the detail text label over
	rect						= self.detailTextLabel.frame;
	rect.origin.x			   += imageWidth;
	rect.size.width			    = self.contentView.frame.size.width - kDueDateWidth - imageWidth - 4;
	self.detailTextLabel.frame	= rect;
}

- (void) setSelected: (BOOL) selected animated: (BOOL) animated
{
    [super setSelected: selected animated: animated];
}

@end