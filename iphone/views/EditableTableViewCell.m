// =============================================================================
//
// Editable table view cell based on code from the Apple EditableDetailView
// example.
//
// =============================================================================

#import "EditableTableViewCell.h"

@implementation EditableTableViewCell

static const int kLabelWidth = 130;

@synthesize valueField;

- (id) initWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
{
	if (self = [super initWithStyle: UITableViewStylePlain reuseIdentifier: reuseIdentifier])
	{
		// This is the light blue color for the value field
		blueColor							= [[UIColor colorWithRed: 0.22 green: 0.33 blue: 0.53 alpha: 1] retain];
	
        valueField							= [[UITextField alloc] initWithFrame: CGRectZero];
        valueField.contentVerticalAlignment	= UIControlContentVerticalAlignmentCenter;
        valueField.font						= [UIFont systemFontOfSize: 16];
        valueField.textColor				= blueColor;
        [self.contentView addSubview: valueField];
		
		// This is an edit cell so it should be selectable
		self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
	
    return self;
}

- (void) dealloc
{
	[blueColor release];
	[valueField release];
    [super dealloc];
}

- (void) layoutSubviews
{
	[super layoutSubviews];
	
	// Start with a rect that is inset from the content view by 10 pixels on all sides
    CGRect baseRect = CGRectInset(self.contentView.bounds, 10, 10);
	
	CGRect rect				= baseRect;
	rect.size.width			= kLabelWidth;
	self.textLabel.frame	= rect;
	
	rect					= baseRect;
	rect.origin.x			= kLabelWidth + 10;
	rect.size.width		   -= kLabelWidth + 10;
	rect.size.height	   += 1;					// Make the height a bit bigger to accomodate the font
	valueField.frame		= rect;
}

- (void) setSelected: (BOOL) selected animated: (BOOL) animated
{
	[super setSelected: selected animated: animated];

	// Don't change the color if selection is disabled
	if (self.selectionStyle != UITableViewCellSelectionStyleNone)
	{
		valueField.textColor = (selected) ? [UIColor whiteColor] : blueColor;
	}
}

- (void) setHighlighted: (BOOL) highlighted animated: (BOOL) animated
{
	[super setHighlighted: highlighted animated: animated];
	
	valueField.textColor = (highlighted) ? [UIColor whiteColor] : blueColor;
	valueField.highlighted = highlighted;
}

@end