#import <Foundation/Foundation.h>

@interface SectionHeaderView : UIView
{
}

+ (UIView *) sectionHeaderViewForTable: (UITableView *) tableView title: (NSString *) title;
- (id) initWithFrame: (CGRect) frame title: (NSString *) title;

@end