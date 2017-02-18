#import "SwitchTableViewCell.h"

@implementation SwitchTableViewCell

@dynamic switchView;

+ (SwitchTableViewCell *) cellForTableView: (UITableView *) tableView
{
	SwitchTableViewCell *cell = (SwitchTableViewCell *) [tableView dequeueReusableCellWithIdentifier: @"SwitchTableViewCell"];
	if (cell == nil)
	{
		cell						= [[[SwitchTableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: @"SwitchTableViewCell"] autorelease];
		UISwitch *view				= [[[UISwitch alloc] initWithFrame: CGRectZero] autorelease];
		cell.accessoryView			= view;
		cell.editingAccessoryView	= view;
		cell.selectionStyle			= UITableViewCellSelectionStyleNone;
	}
	
	return cell;
}

- (UISwitch *) switchView
{
	return (UISwitch *) self.accessoryView;
}

- (void) dealloc
{
    [super dealloc];
}

@end