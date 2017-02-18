#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h> 
#import "Settings.h"

@interface LoansTableViewCell : UITableViewCell
{
	UILabel		*dueDateDay;
	UILabel		*dueDateMonth;
	UILabel		*positionTextLabel;
	CALayer		*verticalRule;
	CALayer		*horizontalRule;
	BOOL		longDivider;
	UIImageView	*backgroundImageView;
	Settings	*settings;
}

@property (nonatomic, retain)	UILabel *dueDateDay;
@property (nonatomic, retain)	UILabel *dueDateMonth;
@property (nonatomic, retain)	UILabel *positionTextLabel;
@property (nonatomic, retain)	UIImageView	*backgroundImageView;
@property						BOOL longDivider;

@end