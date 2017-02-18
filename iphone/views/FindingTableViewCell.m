// =============================================================================
//
// Cell for showing the "Finding" cell.
//
// =============================================================================

#import "FindingTableViewCell.h"

@implementation FindingTableViewCell

// -----------------------------------------------------------------------------
#pragma mark -
#pragma mark Constants

static const int kActivityIndicatorWidth	= 20;
static const int kActivityIndicatorHeight	= 20;
static const int kActivityIndicatorRadius	= 10;

// -----------------------------------------------------------------------------
#pragma mark -

- (id) initWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
{
    if (self = [super initWithStyle: UITableViewCellStyleDefault reuseIdentifier: reuseIdentifier])
	{
		activityIndicatorView		= [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
		[activityIndicatorView startAnimating];
		[self.contentView addSubview: activityIndicatorView];
		
		self.accessoryType		= UITableViewCellAccessoryNone;
		self.selectionStyle		= UITableViewCellSeparatorStyleNone;
		self.textLabel.text		= @"Finding Nearby Libraries";
    }

    return self;
}

- (void) dealloc
{
	[activityIndicatorView release];
    [super dealloc];
}

- (void) layoutSubviews
{
	[super layoutSubviews];
	
	// Start with a rect that is inset from the content view by 10 pixels on all sides
    CGRect baseRect = CGRectInset(self.contentView.bounds, 10, 10);
	
	CGRect rect						= baseRect;
	rect.size.width					= kActivityIndicatorWidth;
	rect.size.height				= kActivityIndicatorHeight;
	rect.origin.y				   += (baseRect.size.height / 2) - kActivityIndicatorRadius;
	activityIndicatorView.frame		= rect;

	// Shift the text label over
	rect					= self.textLabel.frame;
	rect.origin.x			   += activityIndicatorView.frame.size.width + 10;
	rect.size.width			   -= activityIndicatorView.frame.size.width + 10;
	self.textLabel.frame		= rect;
}

@end
