#import <Cocoa/Cocoa.h>

@interface NSMenu (NSMenuExtension)

+ (NSMenu *) menu;
- (void) addSeparatorItem;
- (NSMenuItem *) addItemWithTitle: (NSString *) title action: (SEL) selector;
- (NSMenuItem *) addItemWithTitle: (NSString *) title;
- (NSMenuItem *) addItemWithTitle: (NSString *) title action: (SEL) selector target: (id) target;
- (NSMenuItem *) addItemWithTitle: (NSString *) title action: (SEL) selector target: (id) target representedObject: (id) representedObject;
- (NSMenuItem *) addItemWithImage: (NSImage *) image;
- (NSMenuItem *) addItemWithBoldTitle: (NSString *) title;
- (NSMenuItem *) addItemWithTitleFormat: (NSString *) format, ...;
- (NSMenuItem *) addItemWithBoldTitleFormat: (NSString *) format, ...;
- (NSMenuItem *) addItemWithAttributedString: (NSAttributedString *) string;
- (NSMenuItem *) addItemWithTitle: (NSString *) title description: (NSString *) description;
- (NSMenuItem *) addItemWithView: (NSView *) view;

@end