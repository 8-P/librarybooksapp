#import <Foundation/Foundation.h>

@interface URL : NSURL
{
	NSMutableDictionary	*attributes;
	NSString			*rawAttributes;
	NSDictionary		*headers;
	NSHTTPURLResponse	*response;
	URL					*nextURL;
}

@property(retain, readwrite)	NSMutableDictionary	*attributes;
@property(retain, readwrite)	NSString			*rawAttributes;
@property(retain, readwrite)	NSDictionary		*headers;
@property(retain, readonly)		NSHTTPURLResponse	*response;
@property(retain, readwrite)	URL					*nextURL;

+ (URL *) URLWithURL: (NSURL *) url;
+ (URL *) URLWithFormat: (NSString *) format, ...;
+ (void) setUserAgent: (NSString *) newUserAgent;
- (URL *) URLWithPath: (NSString *) string;
- (URL *) URLWithPathFormat: (NSString *) format, ...;
- (URL *) URLWithParameters: (NSDictionary *) parameters;
- (void) addPostAttributesToRequest: (NSMutableURLRequest *) request;
- (NSString *) download;
- (NSString *) _download;
- (NSString *) base;
- (NSString *) method;
- (void) deleteAssociatedCookies;

// Open URL
- (void) openInWebBrowser;
- (NSString *) redirectPageForPostURL;
- (NSString *) redirectPageForNextURL;
+ (BOOL) defaultBrowserIsSafari;
+ (NSString *) bundleIdentifier: (NSURL *) url;
+ (BOOL) isBundleIdentifierAnEditor: (NSString *) bundleIdentifier;
- (NSString *) defaultUserAgent;

@end