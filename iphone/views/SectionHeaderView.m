#import "SectionHeaderView.h"
#import "UIColorExtras.h"
#import <QuartzCore/QuartzCore.h> 

@implementation SectionHeaderView

+ (UIView *) sectionHeaderViewForTable: (UITableView *) tableView title: (NSString *) title
{
	return nil;

	return [[[SectionHeaderView alloc] initWithFrame: CGRectMake(0, 0, tableView.bounds.size.width, 22) title: title] autorelease];
}

- (id) initWithFrame: (CGRect) frame title: (NSString *) title
{
	self = [super initWithFrame: frame];

	CGFloat width	= frame.size.width;
	CGFloat height	= frame.size.height;
	
	[self setBackgroundColor: [UIColor colorWithHex: 0x02254b alpha: 0.2]];
	
	UILabel *label			= [[[UILabel alloc] initWithFrame: CGRectMake(12, 0, width - 10, height)] autorelease];
	label.text				= title;
	label.textColor			= [UIColor colorWithHex: 0xFFFFFF];
	label.backgroundColor	= [UIColor clearColor];
	label.font				= [UIFont boldSystemFontOfSize: 18];
	label.shadowColor		= [UIColor colorWithHex: 0x000000 alpha: 0.5];
    label.shadowOffset		= CGSizeMake(0, 1);
	[self addSubview: label];
	
	CALayer *rule1			= [[CALayer layer] retain];
	rule1.backgroundColor	= [[UIColor colorWithHex: 0xFFFFFF alpha: 0.3] CGColor];
	rule1.frame				= CGRectMake(0, 0, width, 1);
	[self.layer insertSublayer: rule1 atIndex: 0];
	[rule1 release];
	
	CALayer *rule2			= [[CALayer layer] retain];
	rule2.backgroundColor	= [[UIColor colorWithHex: 0x000000 alpha: 0.2] CGColor];
	rule2.frame				= CGRectMake(0, height - 1, width, 1);
	[self.layer insertSublayer: rule2 atIndex: 0];
	[rule2 release];
	
	return self;
}

@end