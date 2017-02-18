#import "NSPopUpButtonExtras.h"

@implementation NSPopUpButton (NSPopUpButtonExtras)

- (void) selectItemWithRepresentedObject: (id) representedObject
{
	for (NSMenuItem *item in [self itemArray])
	{
		if ([[item representedObject] isEqualToString: representedObject])
		{
			[self selectItem: item];
			break;
		}
	}
}

@end