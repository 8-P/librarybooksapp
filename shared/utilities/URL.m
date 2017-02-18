#import "URL.h"
#import "SharedExtras.h"
#import "Debug.h"
#import "HTMLTidy.h"
#import "RegexKitLite.h"
#import "JSON.h"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#else
#import "HTTPServer.h"
#endif

// Globals ---------------------------------------------------------------------

static NSString	*userAgent = nil;

@implementation URL

@synthesize attributes, rawAttributes, headers, response, nextURL;

+ (URL *) URLWithURL: (NSURL *) url
{
	return [URL URLWithString: [url absoluteString]];
}

+ (URL *) URLWithFormat: (NSString *) format, ...
{
	// Build up the string
	va_list arguments;
	va_start(arguments, format);
	NSString *string = [[NSString alloc] initWithFormat: format arguments: arguments];
	[string autorelease];
	va_end(arguments);
	
	return [URL URLWithString: string];
}

// -----------------------------------------------------------------------------
//
// Convert a URL String to a URL object.
//
// Note that we need to override the base class URLWithString: because it returns
// a pointer to an invalid memory address.  I found that the only way around it
// is to call [NSURL URLWithString:] first.
//
// -----------------------------------------------------------------------------
+ (URL *) URLWithString: (NSString *) urlString
{
	if ([urlString isEqualToString: @""] || urlString == nil) return nil;

	// Fix up special characters
	urlString = [urlString stringByReplacingOccurrencesOfString: @"{" withString: @"%7B"];
	urlString = [urlString stringByReplacingOccurrencesOfString: @"}" withString: @"%7D"];
	
	// Google Book Search and Spydus don't like "&amp;"
	urlString = [urlString stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"];

	NSURL *url = [NSURL URLWithString: urlString];
	if (url == nil)
	{
		[Debug log: @"URL - failed to convert string [%@] to URL", urlString];
		return nil;
	}
	
	return [super URLWithString: [url absoluteString]];
}

// -----------------------------------------------------------------------------
//
// Set the User Agent value for all future requests.
//
//		* Set to nil to restore the default Library Books user agent value.
//
// -----------------------------------------------------------------------------
+ (void) setUserAgent: (NSString *) newUserAgent
{
	userAgent = newUserAgent;
}

- (void) dealloc
{
	[attributes release];
	[response release];
	[headers release];
	[super dealloc];
}

// -----------------------------------------------------------------------------
//
// Perform modifications on the end bits of a URL.
//
// -----------------------------------------------------------------------------
- (URL *) URLWithPath: (NSString *) string
{
	URL *url = nil;
	if (string == nil || [string length] == 0)
	{
		url = self;
	}
	else if ([string hasPrefix: @"http"])
	{
		// The string is a full URL
		url = [URL URLWithString: string];
	}
	else if ([string hasPrefix: @"?"])
	{
		// We are modifying the GET args
		NSString *urlString = [self absoluteString];
		if ([urlString hasSubString: @"?"])
		{
			// This is old behaviour pre 3.0b58 and 1.6.  It was causing trouble
			// with the GET requests.  REMOVE THIS CODE when happy the change is ok
			// return [URL URLWithFormat: @"%@&%@", urlString, [string stringByDeletingOccurrencesOfString: @"?"]];
			
			return [URL URLWithFormat: @"%@%@", [urlString stringUptoFirst: @"?"], string];
		}
		else
		{
			return [URL URLWithFormat: @"%@%@", urlString, string];
		}
	}
	else if ([string hasPrefix: @"../"])
	{
		// Strip off first part and replace
		//		http://blah.com/apple/bannanas  + ../pear	-> http://blah.com/pear
		//		http://blah.com/apple/bannanas/ + ../pear	-> http://blah.com/apple/pear
		
		NSString *urlString = [self absoluteString];
		if ([urlString hasSuffix: @"/"])
		{
			urlString = [urlString urlStringByDeletingLastPathComponent];
		}
		else
		{
			urlString = [urlString urlStringByDeletingLastPathComponent];
			urlString = [urlString urlStringByDeletingLastPathComponent];
		}
		
		return  [URL URLWithFormat: @"%@/%@", urlString, [string stringByDeletingOccurrencesOfString: @"../"]];
	}
	else if ([string hasPrefix: @"/"])
	{
		url = [URL URLWithFormat: @"%@%@", [self base], string];
	}
	else
	{
		// Handle relative URLs
		//		http://blah.com/apple/bannanas/ + blah			-> http://blah.com/apple/bannanas/blah
		//		http://blah.com/apple/bannanas/page.html + blah	-> http://blah.com/apple/bannanas/blah
		NSString *urlString = [self absoluteString];
		if ([[self path] length] > 1)
		{
			if ([urlString hasSuffix: @"/"])
			{
				urlString = [urlString stringUptoLast: @"/"];
			}
			else
			{
				urlString = [urlString urlStringByDeletingLastPathComponent];
			}
		}
		else
		{
			urlString = [self base];
		}

		url = [URL URLWithFormat: @"%@/%@", urlString, string];
	}
	
	return url;
}

// -----------------------------------------------------------------------------
//
//	WARNING: This function will not work properly if you have "%" signs in
//	the URL string.
//
// -----------------------------------------------------------------------------
- (URL *) URLWithPathFormat: (NSString *) format, ...
{
	// Build up the path
	va_list arguments;
	va_start(arguments, format);
	NSString *string = [[[NSString alloc] initWithFormat: format arguments: arguments] autorelease];
	va_end(arguments);
	
	return [self URLWithPath: string];
}

// -----------------------------------------------------------------------------
//
// Perform modifications on the end bits of a URL.
//
// -----------------------------------------------------------------------------
- (URL *) URLWithParameters: (NSDictionary *) parameters
{
	NSMutableArray *keyValuePairs = [NSMutableArray arrayWithCapacity: [parameters count]];
	for (NSString *key in parameters)
	{
		NSString *s = [NSString stringWithFormat: @"%@=%@", [key URLEncode], [[parameters objectForKey: key] URLEncode]];
		[keyValuePairs addObject: s];
	}
	
	NSString *parameterString = [keyValuePairs componentsJoinedByString: @"&"];
	return [self URLWithPathFormat: @"?%@", parameterString];
}

// -----------------------------------------------------------------------------
//
// Download the URL. Handles:
//		* Meta refreshes
//
// -----------------------------------------------------------------------------
- (NSString *) download
{
	URL *url = self;
	
	int t = time(NULL);
	
	for (int i = 0; i < 10; i++)
	{
		NSString *string = [url _download];
		if (string == nil) return nil;
	
		URL *redirectURL = nil;
	
		// Deal with bad redirects like http://www.torontopubliclibrary.ca:443/youraccount
		//                              ^                                  ^
		//                              `-- http (not https)               `-- SSL port
//		NSURL *responseURL = [response URL];
//		if ([[responseURL absoluteString] isMatchedByRegex: @"^http://[^/]+:443"])
//		{
//			[Debug logError: @"%@ - response - ambiguous redirect - assuming https", [self method]];
//			redirectURL = [URL URLWithString: [[responseURL absoluteString] stringByReplacingOccurrencesOfRegex: @"^http://" withString: @"https://"]];
//		}

		// Retry bad gateway errors.  London Public Library returns a bad gateway if
		// you access the site too quickly.  My solution is to:
		//		* Sleep for 2 seconds
		//		* And retry request
		//
		// This problem also happens for Millenium/us.mn.SaintPaulPublicLibrary.  They return
		// and 429 (Too Many Requests).
		if (url.response && [url.response class] == [NSHTTPURLResponse class] && ([url.response statusCode] == 502 || [url.response statusCode] == 429))
		{
			NSTimeInterval sleepTime = 2 + pow(2, i);
			if (sleepTime <= 10)
			{
				[Debug log: @"%@ - detected 502 bad gateway, retrying in [%0.0f s]", [self method], sleepTime];
				[NSThread sleepForTimeInterval: sleepTime];
				continue;
			}
		}
		
		
	
		// Detect meta refreshes
		NSScanner *scanner = [NSScanner scannerWithString: string];
		HTMLElement *element;
		if ([scanner scanNextElementWithName: @"head" intoElement: &element])
		{
			NSString *urlString = [element.value stringByMatching: @"(?i:<meta http-equiv=\"Refresh\"[^>]*? content=\"\\s*[0123]\\s*;\\s*url=([^\"\\r\\n]+))" capture: 1];
			if (urlString)
			{
				URL *currentURL = [URL URLWithURL: [url.response URL]];
				redirectURL = [currentURL URLWithPath: urlString];
			}
		}
	
		if (redirectURL == nil)
		{
			// Make sure the response URL is saved
			if (url.response)
			{
				[response release];
				response = [url.response retain];
			}
		
			string = [HTMLTidy tidy: string url: [URL URLWithURL: [response URL]]];
			[Debug log: @"%@ - took [%d s]", [self method], time(NULL) - t];
			[Debug space];
			
			return string;
		}

		[Debug log: @"Following redirect to [%@]", [redirectURL absoluteString]];
		url = redirectURL;
	}
	
	[Debug logError: @"Too many redirects - giving up"];
	return nil;
}

- (NSString *) _download
{
	NSString *method = [self method];

	// Figure out the request
	NSMutableURLRequest *request = [NSMutableURLRequest
		requestWithURL:		self
		cachePolicy:		NSURLRequestUseProtocolCachePolicy
		timeoutInterval:	30.0
	];
	
	[[NSURLCache sharedURLCache] setMemoryCapacity: 0];
	[[NSURLCache sharedURLCache] setDiskCapacity:   0];
	
	// Set user agent and accept gzip encoding
	[request setValue: (userAgent) ? userAgent : [self defaultUserAgent] forHTTPHeaderField: @"User-Agent"];	
	[request setValue: @"gzip" forHTTPHeaderField: @"Accept-Encoding"];
	
	// Add custom headers
	//		* Evergreen need custom headers to make some of the requests
	if (headers != nil)
	{
		for (NSString *field in headers)
		{
			NSString *value = [headers objectForKey: field];
			[request setValue: value forHTTPHeaderField: field];
		}
	}
	
	[Debug log: @"%@ - request - %@", method, [self absoluteString]];
	
	// Add in post attributes
	if ([method isEqualToString: @"POST"])
	{
		[self addPostAttributesToRequest: request];
		
		if (attributes)
		{
			[Debug logDetails: [attributes description] withSummary: @"%@ - request - post attributes (%d)", method, [attributes count]];
		}
		
		if (rawAttributes)
		{
			[Debug logDetails: rawAttributes withSummary: @"%@ - request - post data", method];
		}
	}
	
	// Debug - print out headers
	NSMutableString *requestHeaders = [NSMutableString string];
	NSDictionary *fields = [request allHTTPHeaderFields];
	for (NSString *key in fields)
	{
		[requestHeaders appendFormat: @"%@: %@\n", key, [fields objectForKey: key]];
	}
	[Debug logDetails: requestHeaders withSummary: @"%@ - request - headers (%d)", method, [fields count]];
	
	// Debug - print out cookies
	NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString: [self absoluteString]]];
	NSString *cookiesDescription = ([cookies count]) ? [cookies description] : @"";
	[Debug logDetails: cookiesDescription withSummary: @"%@ - request - cookies (%d)", method, [cookies count]];

	// Do a synchronous download
	NSError *error;
	[response release];
	NSData *data = [NSURLConnection sendSynchronousRequest: request
		returningResponse: &response error: &error];
	[response retain];
		
	if ([self isEqual: [response URL]] == NO)
	{
		[Debug log: @"%@ - response - redirected to - %@", method, [response URL]];
	}

	// Print out debug for HTTP responses
	NSInteger statusCode = 0;
	if ([response class] == [NSHTTPURLResponse class])
	{
		statusCode = [response statusCode];
	
		[Debug log: @"%@ - response - %d - %@", method, [response statusCode],
			[NSHTTPURLResponse localizedStringForStatusCode: [response statusCode]]];
	
		NSMutableString *responseHeaders = [NSMutableString string];
		NSDictionary *fields = [response allHeaderFields];
		for (NSString *key in fields)
		{
			[responseHeaders appendFormat: @"%@: %@\n", key, [fields objectForKey: key]];
		}
		[Debug logDetails: responseHeaders withSummary: @"%@ - response - headers (%d)", method, [fields count]];
	}
	else
	{
		// We didn't get a NSHTTPURLResponse
		[Debug logDetails: [response description] withSummary: @"%@ - response - non HTTP response", method];
	}
	
	if (data != nil)
	{
		// Figure out the encoding and use it to decode the data
		NSStringEncoding encoding = [NSString stringEncodingForIANACharSetName: [response textEncodingName]];
		NSString *string = [NSString stringWithData: data encoding: encoding];
		if (string == nil && [data length] > 0)
		{
			[Debug logError: @"%@ - failed to decode data (%d bytes), encoding [%@]", method, [data length], [response textEncodingName]];
			[Debug logDetails: [data description] withSummary: @"%@ - data", method];
			
			string = [NSString stringWithData: data encoding: NSISOLatin1StringEncoding];
			[Debug log: @"%@ - trying alternate decoding as ISO latin 1 - %@", method, (string) ? @"success" : @"failed"];
		}

		if (statusCode == 500)
		{
			// Send back nil for error responses
			[Debug logDetails: string withSummary: @"%@ - response - decoded error", method];
			return nil;
		}
		else
		{
			[Debug logDetails: string withSummary: @"%@ - response - decoded data", method];
			return string;
		}
	}
	
	[Debug log: @"%@ - response - failure - %@", method, [error localizedDescription]];
	[Debug space];
	return nil;
}

- (void) addPostAttributesToRequest: (NSMutableURLRequest *) request
{
	[request setHTTPMethod: @"POST"];
	[request addValue: @"application/x-www-form-urlencoded" forHTTPHeaderField: @"Content-Type"];

	NSMutableString *httpBody = [NSMutableString string];
	if (rawAttributes != nil)
	{
		// For HTTP requests without a key value pair.  Used by Atriuum
		[httpBody appendString: rawAttributes];
	}
	else
	{
		for (NSString *key in attributes)
		{
			id attribute	= [attributes objectForKey: key];
			key				= [key URLEncode];
			
			if ([attribute isKindOfClass: [NSString class]])
			{
				[httpBody appendFormat: @"%@=%@&", key, [attribute URLEncode]];
			}
			else if ([attribute isKindOfClass: [NSArray class]])
			{
				for (NSString *value in attribute)
				{
					[httpBody appendFormat: @"%@=%@&", key, [value URLEncode]];
				}
			}
		}
	}
	
	// Note that we strip off the last character "&".  Some systems
	// don't like the trailing ampersand
	[request setHTTPBody: [NSData dataWithBytes: [httpBody cStringUsingEncoding: NSASCIIStringEncoding]
		length: [httpBody lengthOfBytesUsingEncoding: NSASCIIStringEncoding] - 1]];
}

// Retruns only the host component of the catalogue URL.
- (NSString *) base
{	
	NSString *portString = @"";
	NSNumber *port = [self port];
	if (port != nil) portString = [NSString stringWithFormat: @":%@", [port stringValue]];
	
	NSString *base = [NSString stringWithFormat: @"%@://%@%@",
		[self scheme], [self host], portString];
		
	return base;
}

- (NSString *) description
{
	return [super description];
}

- (NSString *) method
{
	return ((attributes != nil && [attributes count] > 0) || (rawAttributes != nil && [rawAttributes length] > 0)) ? @"POST" : @"GET";
}

// -----------------------------------------------------------------------------
//
// Delete all cookies associated with this URL.
//
// -----------------------------------------------------------------------------
- (void) deleteAssociatedCookies
{
	NSHTTPCookieStorage *cookieStorage	= [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies					= [cookieStorage cookiesForURL: [NSURL URLWithString: [self absoluteString]]];
	
	NSString *cookiesDescription = ([cookies count]) ? [cookies description] : @"";
	[Debug logDetails: cookiesDescription withSummary: @"URL - deleting cookies (%d)", [cookies count]];
	for (NSHTTPCookie *cookie in cookies)
	{
		[cookieStorage deleteCookie: cookie];
	}
}

// =============================================================================
#pragma mark -
#pragma mark Open URL

// -----------------------------------------------------------------------------
//
// Open the URL in the default web browser.
//
// TODO:	* handle user selected browser.
//
// -----------------------------------------------------------------------------
- (void) openInWebBrowser
{
	NSURL *url = [NSURL URLWithString: [self absoluteString]];

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	[[UIApplication sharedApplication] openURL: url];
#else
	if ([[self method] isEqualToString: @"POST"])
	{
		NSString *html;
		if      (nextURL &&  rawAttributes)	html = [self redirectPageForNextURLWithRawAttributes];
		else if (nextURL && !rawAttributes)	html = [self redirectPageForNextURL];
		else								html = [self redirectPageForPostURL];
		
		url = [[HTTPServer sharedHTTPServer] serveContent: html];
		
		[Debug logDetails: html withSummary: @"POST - redirect page"];
	}
	
	NSString *bundleIdentifier = [URL bundleIdentifier: url];
	[Debug log: @"Opening in [%@]", bundleIdentifier];

	if ([URL isBundleIdentifierAnEditor: bundleIdentifier])
	{
		// Open with Safari
		[Debug logError: @"Opening in Safari instead"];
		[[NSWorkspace sharedWorkspace] openURLs: [NSArray arrayWithObject: url]
			withAppBundleIdentifier: @"com.apple.Safari" options: 0 additionalEventParamDescriptor: nil
			launchIdentifiers: nil];
	}
	else
	{
		[[NSWorkspace sharedWorkspace] openURL: url];
	}
#endif
}

+ (BOOL) defaultBrowserIsSafari
{
	NSString *bundleIdentifier = [URL bundleIdentifier: [NSURL URLWithString: @"http://google.com"]];
	return [bundleIdentifier isEqualToString: @"com.apple.Safari"];
}

+ (NSString *) bundleIdentifier: (NSURL *) url
{
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	return nil;
#else
	CFURLRef defaultHandlerURL;
	LSGetApplicationForURL((CFURLRef) url, kLSRolesViewer, NULL, &defaultHandlerURL);
	NSBundle *bundle = [NSBundle bundleWithPath: [(NSURL *) defaultHandlerURL path]];
	
	return [bundle bundleIdentifier];
#endif
}

+ (BOOL) isBundleIdentifierAnEditor: (NSString *) bundleIdentifier
{
	return [bundleIdentifier isEqualToString: @"com.barebones.bbedit"]
		|| [bundleIdentifier isEqualToString: @"com.macrabbit.Espresso"]
		|| [bundleIdentifier isEqualToString: @"com.apple.TextEdit"]
		|| [bundleIdentifier isEqualToString: @"com.macromates.textmate"]
		|| [bundleIdentifier isEqualToString: @"com.metakine.magic-launch.pref"];
}

- (NSString *) redirectPageForPostURL
{
	NSMutableString *html = [NSMutableString stringWithFormat:
		@"<html>																				\n"
		@"<head><title>Loading...</title></head>												\n"
		@"<body onload='document.hidden_form.__submit__()'>										\n"
		@"<form name='hidden_form' method='post' action='%@'>									\n"
		@"<script type='text/javascript'>hidden_form.__submit__ = hidden_form.submit</script>	\n",
		[self absoluteString]
	];
	
	// Add in post attributes
	for (NSString *key in attributes)
	{
		NSString *value = [attributes objectForKey: key];
		[html appendFormat: @"<input type='hidden' name='%@' value='%@'>\n", key, value];
	}
	
	[html appendFormat:
		@"</form>\n"

		@"</body>\n"
		@"</html>\n"
	];
	
	return html;
}

// -----------------------------------------------------------------------------
//
// This redirect page is used when nextURL is set.
//
//		* Posts the form to an IFRAME and then loads the next URL.
//		* The onload event fires twice so we need to ignore the first one.
//
// -----------------------------------------------------------------------------
- (NSString *) redirectPageForNextURL
{
	NSMutableString *html = [NSMutableString stringWithFormat:
		@"<html>																				\n"
		@"<head><title>Loading...</title></head>												\n"
		@"<body onload='document.hiddenForm.__submit__()'>										\n"
		@"<script>																				\n"
		@"	var state = 1;																		\n"
		@"	function iFrameLoaded() {															\n"
		@"		if (state == 2) {																\n"
		@"			setTimeout('loadNextURL()', 2000);											\n"
		@"		}																				\n"
		@"		state++;																		\n"
		@"	}																					\n"
		@"	function loadNextURL() {															\n"
		@"		document.location.href = '%@';													\n"
		@"	}																					\n"
		@"</script>																				\n"
		@"<iframe name='hiddenIframe' height='1' width='1' style='visibility: hidden'			\n"
		@"	onload='iFrameLoaded()'></iframe>													\n"
		@"<form name='hiddenForm' method='post' action='%@' target='hiddenIframe'>				\n"
		@"<script>hiddenForm.__submit__ = hiddenForm.submit</script>							\n",
		[nextURL absoluteString], [self absoluteString]
	];
	
	// Add in post attributes
	for (NSString *key in attributes)
	{
		NSString *value = [attributes objectForKey: key];
		[html appendFormat: @"<input type='hidden' name='%@' value='%@'>\n", key, value];
	}
	
	[html appendFormat:
		@"</form>\n"

		@"</body>\n"
		@"</html>\n"
	];
	
	return html;
}

// -----------------------------------------------------------------------------
//
// This redirect page is used when nextURL is set.
//
//		* Does an AJAX POST to submit URL request.
//		* On completion it opens the nextURL.
//
// -----------------------------------------------------------------------------
- (NSString *) redirectPageForNextURLWithRawAttributes
{
	NSMutableString *html = [NSMutableString stringWithFormat:
		@"<html>																				\n"
		@"<head><title>Loading...</title></head>												\n"
		@"<body>																				\n"
		@"<script type='text/javascript'														\n"
		@"	src='http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js'></script>		\n"
		@"<script>																				\n"
		@"$.post('%@', %@,																		\n"
		@"	function(data) {																	\n"
		@"		document.location.href = '%@';													\n"
		@"	}																					\n"
		@");																					\n"
		@"</script>																				\n"
		@"</body>																				\n"
		@"</html>																				\n",
		[self absoluteString],
		(rawAttributes) ? [JSON toString: rawAttributes] : [JSON toString: attributes],
		[nextURL absoluteString]
	];
	
	return html;
}

- (NSString *) defaultUserAgent
{
	return [NSString stringWithFormat: @"LibraryBooks/%@ (%@)",
		[[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleVersion"],
		[[NSProcessInfo processInfo] operatingSystemVersionString]
	];
}

@end