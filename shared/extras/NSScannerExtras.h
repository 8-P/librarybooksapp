#import <Foundation/Foundation.h>
#import "HTMLElement.h"
#import "OrderedDictionary.h"

@interface NSScanner (NSScannerExtras)

+ (NSScanner *) scannerWithString: (NSString *) string;
- (BOOL) scanUpToString: (NSString *) stopString;
- (BOOL) scanPassString: (NSString *) stopString;
- (BOOL) scanFromString: (NSString *) leftString upToString: (NSString *) rightString intoString: (NSString **) stringValue;
- (BOOL) scanFromString: (NSString *) leftString upToString: (NSString *) rightString intoFloat: (float *) value;
- (NSMutableDictionary *) hiddenFormAttributes;
- (BOOL) scanRegex: (NSString *) regex capture: (NSInteger) capture intoString: (NSString **) stringValue;
- (NSString *) linkForLabel: (NSString *) label;
- (NSString *) linkForHrefRegex: (NSString *) regex;
- (BOOL) scanPassHead;
- (HTMLElement *) head;
- (BOOL) scanNextElementWithName: (NSString *) name intoElement: (HTMLElement **) element;
- (BOOL) scanNextElementWithNames: (NSArray *) names intoElement: (HTMLElement **) element;
- (BOOL) scanNextElementWithName: (NSString *) name attributes: (NSDictionary *) attributes
	intoElement: (HTMLElement **) element recursive: (BOOL) recursive;
- (BOOL) scanNextElementWithName: (NSString *) name attributeKey: (NSString *) key attributeValue: (NSString *) value
	intoElement: (HTMLElement **) element recursive: (BOOL) recursive;
- (BOOL) scanNextElementWithName: (NSString *) name attributes: (NSDictionary *) attributes
	intoElement: (HTMLElement **) element;
- (BOOL) scanNextElementWithName: (NSString *) name attributeKey: (NSString *) key attributeValue: (NSString *) value
	intoElement: (HTMLElement **) element;
- (BOOL) scanNextElementWithName: (NSString *) name regexValue: (NSString *) value
	intoElement: (HTMLElement **) element;
- (BOOL) scanPassElementWithName: (NSString *) name;
- (BOOL) scanPassElementWithName: (NSString *) name attributeKey: (NSString *) key attributeValue: (NSString *) value;
- (BOOL) scanNextElementWithName: (NSString *) name attributeKey: (NSString *) key attributeRegex: (NSString *) regex
	intoElement: (HTMLElement **) element;
- (BOOL) scanPassElementWithName: (NSString *) name regexValue: (NSString *) regexValue;

- (NSArray *) tableWithColumns: (NSArray *) columns ignoreRows: (NSArray *) ignoreRows delegate: (id) delegate ignoreFirstRow: (BOOL) ignoreFirstRow;
- (NSArray *) tableWithColumns: (NSArray *) columns ignoreRows: (NSArray *) ignoreRows delegate: (id) delegate;
- (NSArray *) tableWithColumns: (NSArray *) columns ignoreRows: (NSArray *) ignoreRows;
- (NSArray *) tableWithColumns: (NSArray *) columns;
- (NSArray *) analyseTableColumnsUsingDictionary: (OrderedDictionary *) dictionary;
- (NSArray *) analyseLoanTableColumns;
- (NSArray *) analyseHoldTableColumns;
- (NSArray *) javascriptWithKeyMapping: (NSDictionary *) mapping;
- (NSDictionary *) analyseUsingDictionary: (OrderedDictionary *) dictionary;
- (NSDictionary *) dictionaryUsingRegexMapping: (OrderedDictionary *) mapping;
- (NSScanner *) scannerForElementWithName: (NSString *) name attributeKey: (NSString *) key attributeRegex: (NSString *) regex;

@end