// -----------------------------------------------------------------------------
//
// Emulates a browser.
//
// -----------------------------------------------------------------------------

#import "Browser.h"
#import "Debug.h"

@implementation Browser

@synthesize currentURL, scanner;

+ (Browser *) browser
{
	return [[[Browser alloc] init] autorelease];
}

- (id) init
{
	self = [super init];
	scanner = [[NSScanner scannerWithString: @""] retain];
	
	// Clear the cache.  This is necessary to remove bad cache results
	[self clearCache];
	
	// Reset the User Agent field
	[URL setUserAgent: nil];
	
	return self;
}

- (void) dealloc
{
	[currentURL release];
	[scanner release];
	[frameName release];
	
	[super dealloc];
}

// TODO: add options to follow redirects etc.
- (BOOL) go: (URL *) url
{
	if (url == nil) return NO;

	NSString *page = [url download];
	if (page == nil) return NO;
	
	// Handle frames
	if (frameName)
	{
		[scanner release];
		scanner = [[NSScanner scannerWithString: page] retain];
		
		HTMLElement *element;
		if ([scanner scanNextElementWithName: @"frame " attributeKey: @"name" attributeValue: frameName intoElement: &element])
		{
			URL *frameUrl	= [URL URLWithURL: [url.response URL]];
			frameUrl		= [frameUrl URLWithPath: [element.attributes objectForKey: @"src"]];
			[Debug log: @"Browser - focus on frame [%@] - %@", frameName, [frameUrl absoluteString]];
			
			page = [frameUrl download];
			if (page == nil) return NO;
		}
	}
	
	// Load the scanner with the page
	[scanner release];
	scanner = [[NSScanner scannerWithString: page] retain];
	
	// Remember the current URL so we can deal with relative URLs.  Note that
	// we have to get it from url.response because it may have changed due to
	// a HTTP redirect
	[currentURL release];
	currentURL = [[URL URLWithURL: [url.response URL]] retain];

	return YES;
}

- (BOOL) clickLink: (NSString *) label
{
	return [self go: [self linkForLabel: label]];
}

- (URL *) linkForLabel: (NSString *) label
{
	NSString *href = [scanner linkForLabel: label];
	if (href == nil) return nil;
	
	URL *url = [currentURL URLWithPath: href];
	if (url == nil) return nil;
	
	return url;
}

- (URL *) linkForHrefRegex: (NSString *) regex
{
	NSString *href = [scanner linkForHrefRegex: regex];
	if (href == nil) return nil;
	
	URL *url = [currentURL URLWithPath: href];
	if (url == nil) return nil;
	
	return url;
}

- (URL *) firstLinkForLabels: (NSArray *) labels
{
	for (NSString *label in labels)
	{
		URL *url = [self linkForLabel: label];
		if (url) return url;
	}
	
	return nil;
}

- (BOOL) clickFirstLink: (NSArray *) labels
{
	for (NSString *label in labels)
	{
		if ([self clickLink: label]) return YES;
	}
	
	return NO;
}

// -----------------------------------------------------------------------------
//
// Find and submit the form with a matching name/id.
//
// Set name = @"" if you just want to submit the first form.
//
// -----------------------------------------------------------------------------
- (BOOL) submitFormNamed: (NSString *) name entries: (NSDictionary *) entries
{
	URL *url = [self linkToSubmitFormNamed: name entries: entries];
	if (url == nil) return NO;
	
	return [self go: url];
}

- (BOOL) submitFirstForm
{
	return [self submitFormNamed: nil entries: nil];
}

// -----------------------------------------------------------------------------
//
// Find the right form and return URL to submit it.
//
//		* Set name = nil or @"" to submit the first <form>
//		* set name = @"AUTO" to autodetect the the first form with matching <input>
//		  entries
//
// -----------------------------------------------------------------------------
- (URL *) linkToSubmitFormNamed: (NSString *) name entries: (NSDictionary *) entries
{
	HTMLElement *element;
	if (name == nil || [name isEqualToString: @""])
	{
		if ([scanner scanNextElementWithName: @"form" intoElement: &element] == NO)
		{
			return nil;
		}
	}
	else if ([name isEqualToString: @"AUTO"])
	{
		BOOL ok = NO;
		while (ok == NO && [scanner scanNextElementWithName: @"form" intoElement: &element])
		{
			[Debug logDetails: element.value withSummary: @"Analysing form"];
			
			// Strip out comments from the form
			//
			//		* Started doing this because one of the Millennium forms
			//		  had commented out <input> fields and it stopped the
			//		  automatic parsing from working
			NSString *formString = [element.value stringWithoutHTMLComments];
			if ([formString isEqualToString: element.value] == NO)
			{
				[Debug logDetails: formString withSummary: @"Analysing form - removed comments"];
			}
			
			NSScanner *formScanner = [NSScanner scannerWithString: formString];
			for (NSString *name in [entries allKeys])
			{
				ok = ok || [formScanner scanPassElementWithName: @"input" attributeKey: @"name" attributeValue: name];
//				NSLog(@"key = %@, %d", name, ok);
			}
		}
		
		if (ok == NO) return nil;
	}
	else
	{
		if (   [scanner scanNextElementWithName: @"form" attributeKey: @"name" attributeValue: name
				   intoElement: &element] == NO
			&& [scanner scanNextElementWithName: @"form" attributeKey: @"id" attributeValue: name
				   intoElement: &element] == NO)
		{
			return nil;
		}
	}
	
	NSString *action = [element.attributes objectForKey: @"action"];
	URL *url;
	if (action)
	{
		url = [currentURL URLWithPath: action];
		if (url == nil) return nil;
	}
	else
	{
		url = currentURL;
	}
	
	// Build up the form post values from the hidden input values and
	// entries
	NSScanner *formScanner = [NSScanner scannerWithString: element.value];
	NSMutableDictionary *attributes = [formScanner hiddenFormAttributes];
	[attributes addEntriesFromDictionary: entries];
	
	NSString *method = [element.attributes objectForKey: @"method"];
	if (method && [method hasCaseInsensitiveSubString: @"get"])
	{
		url = [url URLWithParameters: attributes];
	}
	else
	{
		url.attributes = attributes;
	}
	
	return url;
}

// -----------------------------------------------------------------------------
//
// For working with sites with frames.  Call this method to lock all future
// page requests to the frame with the specified name.
//
// -----------------------------------------------------------------------------
- (void) focusOnFrameNamed: (NSString *) name
{
	frameName = [name retain];
}

// -----------------------------------------------------------------------------
//
// Clear the cache.
//
//		* I found that this is needed to prevent a problem with the Millennium
//		  catalogues.  If you did an update when the network is out (e.g. at
//		  wakeup or by manually turning off the ethernet) then the subsequent
//		  updates won't work.  The problem was resolved by clearing the cache.
//
// -----------------------------------------------------------------------------
- (void) clearCache
{
	[[NSURLCache sharedURLCache] removeAllCachedResponses];
}

// -----------------------------------------------------------------------------
//
// Use a mobile User Agent string.
//
//		* Needed by some libraries to trick in into display the mobile version
//		  of the site.
//
// -----------------------------------------------------------------------------
- (void) useMobileUserAgent
{
	[URL setUserAgent: @"Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1A543 Safari/419.3"];
}

- (void) deleteCookies: (URL *) url
{
	NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	NSArray *cookies = [cookieStorage cookiesForURL: [NSURL URLWithString: [url absoluteString]]];
	
	if ([cookies count] > 0)
	{
		[Debug logDetails: [cookies description] withSummary: @"Removing cookies [%d]", [cookies count]];
		for (NSHTTPCookie *cookie in cookies)
		{
			[cookieStorage deleteCookie: cookie];
		}
	}
}

@end