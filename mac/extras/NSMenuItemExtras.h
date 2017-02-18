#import <Cocoa/Cocoa.h>

@interface NSMenuItem (NSMenuItemExtras)

+ (NSMenuItem *) dottedSeparatorItem;
+ (NSMenuItem *) sectionItemWithTitle: (NSString *) title;
+ (NSMenuItem *) spacerItem;

@end