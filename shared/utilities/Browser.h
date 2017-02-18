#import <Foundation/Foundation.h>
#import "SharedExtras.h"
#import "URL.h"

@interface Browser : NSObject
{
	URL			*currentURL;
	NSScanner	*scanner;
	NSString	*frameName;
}

@property(retain, readonly) URL			*currentURL;
@property(retain, readonly) NSScanner	*scanner;

+ (Browser *) browser;
- (BOOL) go: (URL *) url;
- (BOOL) clickLink: (NSString *) label;
- (URL *) linkForLabel: (NSString *) label;
- (URL *) linkForHrefRegex: (NSString *) regex;
- (URL *) firstLinkForLabels: (NSArray *) labels;
- (BOOL) clickFirstLink: (NSArray *) labels;
- (BOOL) submitFormNamed: (NSString *) name entries: (NSDictionary *) entries;
- (BOOL) submitFirstForm;
- (URL *) linkToSubmitFormNamed: (NSString *) name entries: (NSDictionary *) entries;
- (void) focusOnFrameNamed: (NSString *) name;
- (void) clearCache;
- (void) useMobileUserAgent;
- (void) deleteCookies: (URL *) url;

@end