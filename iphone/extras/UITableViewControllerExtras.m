#import "UITableViewControllerExtras.h"

@implementation UITableViewController (UITableViewControllerExtras)

- (CGFloat) screenWidth
{
	CGFloat width;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		width = (UIDeviceOrientationIsPortrait(self.interfaceOrientation)) ? 768 : 1024;
	}
	else
	{
		width = (UIDeviceOrientationIsPortrait(self.interfaceOrientation)) ? 320 : 480;
	}
	width -= 40;
	
	return width;
}

@end
