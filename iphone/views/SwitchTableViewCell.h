#import <UIKit/UIKit.h>

@interface SwitchTableViewCell : UITableViewCell
{
}

@property (readonly) UISwitch *switchView;

+ (SwitchTableViewCell *) cellForTableView: (UITableView *) tableView;

@end