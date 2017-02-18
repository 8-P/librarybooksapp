// =============================================================================
//
// This cell is use in the history view.  It is pretty much the same as the
// normal view but the text size has been stretched out to more text appears on
// the screen and matches the style of the loans and holds views.
//
// =============================================================================

#import "HistoryTableViewCell.h"

static const int kImageWidth = 39;

@implementation HistoryTableViewCell

- (id) initWithStyle: (UITableViewCellStyle) style reuseIdentifier: (NSString *) reuseIdentifier
{
    if (self = [super initWithStyle: style reuseIdentifier: reuseIdentifier])
	{
		settings = [[Settings sharedSettings] retain];
    }

    return self;
}

- (void) dealloc
{
	[settings release];
    [super dealloc];
}

- (void) layoutSubviews
{
	[super layoutSubviews];

	// Image width
	int imageWidth = (settings.bookCovers) ? kImageWidth : 0;

	// Show/hide the image
	CGRect rect					= self.imageView.frame;
	rect.size.width				= imageWidth;
	self.imageView.frame		= rect;

	// Make the text label as long as possible
	rect						 = self.textLabel.frame;
	rect.origin.x				 = imageWidth + 6;
	rect.size.width			     = self.contentView.frame.size.width - imageWidth - 5;
	self.textLabel.frame		 = rect;

	rect						 = self.detailTextLabel.frame;
	rect.origin.x				 = imageWidth + 6;
	rect.size.width			     = self.contentView.frame.size.width - imageWidth - 5;
	self.detailTextLabel.frame	 = rect;
}

@end