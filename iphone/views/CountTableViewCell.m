#import "CountTableViewCell.h"

@implementation CountTableViewCell

- (id) initWithFrame: (CGRect) frame reuseIdentifier: (NSString *) reuseIdentifier
{
    if (self = [super initWithStyle: UITableViewCellStyleDefault reuseIdentifier: reuseIdentifier])
	{
		self.selectionStyle				= UITableViewCellSelectionStyleNone;
		self.textLabel.font				= [UIFont systemFontOfSize: 18];
		self.textLabel.textColor		= [UIColor grayColor];
		self.textLabel.textAlignment	= UITextAlignmentCenter;
	}
	
	return self;
}

@end