#import "SliderTableViewCell.h"

@implementation SliderTableViewCell

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
    if (self = [super initWithStyle: UITableViewCellStyleValue1 reuseIdentifier: reuseIdentifier])
	{
		slider						= [[UISlider alloc] init];
		slider.minimumValue			= 0;
		slider.maximumValue			= 14;
		slider.value				= 1;
		[slider addTarget: self action:@selector(sliderValueChanged:) forControlEvents: UIControlEventValueChanged];
		[self.contentView addSubview: slider];
		
		self.accessoryType			= UITableViewCellAccessoryNone;
		self.selectionStyle			= UITableViewCellSeparatorStyleNone;
		
		self.detailTextLabel.text	= @"Off";
		self.textLabel.text			= @"xxxxxxxxxxxxxxxxxxxxxxxxxx";
    }

    return self;
}

- (void) sliderValueChanged: (id) sender
{
	int value = (int) slider.value;
	if (value == 0)
	{
		self.detailTextLabel.text = @"Off";
	}
	else
	{
		self.detailTextLabel.text = [NSString stringWithFormat: @"%d", value];
	}
}

- (void) dealloc
{
	[slider release];
    [super dealloc];
}

- (void) layoutSubviews
{
	[super layoutSubviews];
	
	slider.frame			= self.textLabel.frame;
	self.textLabel.frame	= CGRectZero;
}

@end
