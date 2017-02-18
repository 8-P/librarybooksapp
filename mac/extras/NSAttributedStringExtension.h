#import <Cocoa/Cocoa.h>

@interface NSAttributedString (NSAttributedStringExtension)

+ (NSAttributedString *) string: (NSString *) string attributes: (NSDictionary *) attributes;
+ (NSAttributedString *) normalMenuString: (NSString *) string;
+ (NSAttributedString *) normalPopUpMenuString: (NSString *) string;
+ (NSAttributedString *) boldMenuString: (NSString *) string;
+ (NSAttributedString *) smallDisabledMenuString: (NSString *) string;
+ (NSAttributedString *) tinyDisabledMenuString: (NSString *) string;
+ (NSAttributedString *) tinyItalicDisabledMenuString: (NSString *) string;
+ (NSAttributedString *) smallMenuString: (NSString *) string;
+ (NSAttributedString *) smallBoldMenuString: (NSString *) string;
+ (NSAttributedString *) paragraphBreak;
+ (NSAttributedString *) htmlString: (NSString *) string;
+ (NSAttributedString *) tinyMenuStringAtNormalHeight: (NSString *) string;

@end