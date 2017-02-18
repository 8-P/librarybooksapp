// =============================================================================
//
// UIColor factory for generating common colours.
//
// =============================================================================

#import "UIColorFactory.h"
#import "UIColorExtras.h"
#import "SingleLibrary.h"

@implementation UIColorFactory

// -----------------------------------------------------------------------------
//
// The colour of the table view cell separator.  Figured out by using a colour
// picker on it.
//
// -----------------------------------------------------------------------------
+ (UIColor *) tableViewCellSeparatorColor
{
	return [UIColor colorWithRed: 0.878 green: 0.878 blue: 0.878 alpha: 1];
}

+ (UIColor *) blueTextColor
{
	return [UIColor colorWithRed: 0.22 green: 0.33 blue: 0.53 alpha: 1];
}

+ (UIColor *) themeColor
{
	SingleLibrary *singleLibrary = [SingleLibrary sharedSingleLibrary];
	if (singleLibrary.enabled)
	{
		return [UIColor colorWithHex: singleLibrary.themeColour];
	}
	else
	{
		return nil;
	}
}

@end