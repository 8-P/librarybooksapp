#import <Foundation/Foundation.h>

@interface NSString (NSStringExtras)

- (NSString *) URLEncode;
- (NSString *) URLObfuscate;
- (BOOL) hasSubString: (NSString *) string;
- (BOOL) hasSubStringWithFormat: (NSString *) format, ...;
- (BOOL) hasCaseInsensitiveSubString: (NSString *) string;
- (int) countOccurancesOfCaseInsensitiveSubString: (NSString *) string;
- (NSString *) stringByDeletingOccurrencesOfString: (NSString *) string;
- (NSString *) stringWithoutHTML;
- (NSString *) stringToHTML;
+ (NSString *) stringWithData: (NSData *) data encoding: (NSStringEncoding) encoding;
+ (NSStringEncoding) stringEncodingForIANACharSetName: (NSString *) name;
- (NSString *) stringWithBase64Encoding;
- (NSString *) stringByTrimmingWhitespace;
- (BOOL) isNumber;
- (NSString *) stringWithoutHTMLComments;
- (NSString *) stringWithoutHTMLScripts;
- (BOOL) hasWord: (NSString *) string;
- (BOOL) hasWords: (NSArray *) words;
- (NSArray *) words;
- (NSString *) stringUptoLast: (NSString *) string;
- (NSString *) stringUptoFirst: (NSString *) string;
- (NSString *) stringWithoutQuotes;
- (NSString *) nilIfEmpty;
- (NSString *) urlStringByDeletingLastPathComponent;
- (BOOL) splitStringOn: (NSString *) divider  intoLeft: (NSString **) left intoRight: (NSString **) right
	options: (unsigned) mask;
- (BOOL) splitStringOnFirst: (NSString *) divider intoLeft: (NSString **) left intoRight: (NSString **) right;
- (BOOL) splitStringOnLast: (NSString *) divider intoLeft: (NSString **) left intoRight: (NSString **) right;
- (NSString *) stringByDeletingOccurrencesOfRegex: (NSString *) regex;
- (NSString *) md5AsLowerCaseHex;
- (NSString *) stringWithQuotes;

@end