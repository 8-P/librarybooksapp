#import <AppKit/AppKit.h>

@interface NSTextField (NSTextFieldExtras)

+ (NSTextField *) tinyLabelWithFrame: (NSRect) frame;
+ (NSTextField *) tinyLabelWithFrame: (NSRect) frame alignment: (NSTextAlignment) alignment;
+ (NSTextField *) boldLabelWithFrame: (NSRect) frame;
+ (NSTextField *) boldLabelWithFrame: (NSRect) frame alignment: (NSTextAlignment) alignment;
+ (NSTextField *) menuLabelWithFrame: (NSRect) frame;
+ (NSTextField *) menuLabelWithFrame: (NSRect) frame alignment: (NSTextAlignment) alignment;
+ (NSTextField *) menuLabelWithFrame: (NSRect) frame size: (CGFloat) size;

@end