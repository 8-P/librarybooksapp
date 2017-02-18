#import <UIKit/UIKit.h>

@interface EditableTableViewCell : UITableViewCell
{
	UIColor *blueColor;
	UITextField *valueField;
}

@property (nonatomic, retain) UITextField *valueField;

@end