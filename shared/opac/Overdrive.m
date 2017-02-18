// =============================================================================
//
// Overdrive.
//
// =============================================================================

#import "Overdrive.h"
#import "HTMLTidySettings.h"

@implementation Overdrive

- (BOOL) update
{
	// us.wa.SnoIsleLibraries has the links inside JavaScript and the parser
	// can't handle it
	[NSScannerSettings sharedSettings].ignoreHTMLScripts = YES;
	
	URL *myAccountURL = [self myAccountURL];
	if ([browser go: myAccountURL] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

	URL *loansURL = [browser firstLinkForLabels: [self loansLinkLabels]];
	URL *holdsURL = [browser firstLinkForLabels: [self holdsLinkLabels]];
	
	[Debug log: @"Found links for loans [%@], holds [%@]", loansURL.absoluteString, holdsURL.absoluteString];

//	loansURL = [Test fileURLFor: @"Overdrive/20130729_snoisles_account.html"];
//	loansURL = [Test fileURLFor: @"Overdrive/20130728_richmond_loans.html"];

	if (loansURL)
	{
		[browser go: loansURL];
		[self parseLoans1];
		if (loansCount == 0) [self parseLoans2];
	}
	
	if (holdsURL)
	{
		[browser go: holdsURL];
		[self parseHolds1];
	}
	else
	{
		[self parseHolds2];
	}
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Loans format 1.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<b>(.*?)</b>",				@"title",
		@"new Date\\s*\\(\"(.*?)\"\\)", @"",		// Ignore the first date value 
		@"new Date\\s*\\(\"(.*?)\"\\)", @"dueDate",
		nil
	];
	
	[scanner scanPassString: @"<hr"];
	
	NSMutableArray *rows = [NSMutableArray array];
	while ([scanner scanNextElementWithName: @"table" regexValue: @"DisplayEnhancedTitleLink" intoElement: &element])
	{
		[Debug logDetails: element.value withSummary: @"Parsing row"];
		NSMutableDictionary *row = [[[element.scanner dictionaryUsingRegexMapping: mapping] mutableCopy] autorelease];
		[rows addObject: row];
	}
	
	[self addEBookLoans: rows];
}

// -----------------------------------------------------------------------------
//
// Loans format 2.
//
//		* This one is used by us.va.RichmondPublicLibrary.
//
// -----------------------------------------------------------------------------
- (void) parseLoans2
{
	[Debug log: @"Parsing loans (format 2)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<div.*?class=\"trunc-title-line\".*?>(.*?)</div>",	@"title",
		@"<div.*?class=\"trunc-author-line\".*?>(.*?)</div>",	@"author",
		@"<noscript>(.*?)</noscript>",							@"dueDate",
		nil
	];
	
	[scanner scanPassString: @"<h4>Bookshelf</h4>"];

	NSMutableArray *rows = [NSMutableArray array];
	if ([scanner scanNextElementWithName: @"ul" attributeKey: @"id" attributeValue: @"bookshelfBlockGrid" intoElement: &element recursive: YES])
	{
		scanner = element.scanner;
		while ([scanner scanNextElementWithName: @"li" intoElement: &element])
		{
			[Debug logDetails: element.value withSummary: @"Parsing row"];
			NSMutableDictionary *row = [[[element.scanner dictionaryUsingRegexMapping: mapping] mutableCopy] autorelease];
			[rows addObject: row];
		}
	}
	
	[self addEBookLoans: rows];
}

// -----------------------------------------------------------------------------
//
// Holds format 1.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<strong>(.*?)</strong>",								@"title",
		@"(You are patron .*? list|Email notification sent)",	@"queueDescription",
		nil
	];
	
	[scanner scanPassString: @"<hr"];
	
	NSMutableArray *rows = [NSMutableArray array];
	while ([scanner scanNextElementWithName: @"table" regexValue: @"DisplayEnhancedTitleText" intoElement: &element])
	{
		[Debug logDetails: element.value withSummary: @"Parsing row"];
		NSMutableDictionary *row = [[[element.scanner dictionaryUsingRegexMapping: mapping] mutableCopy] autorelease];
		[rows addObject: row];
	}
	
	[self addEBookHolds: rows];
}

// -----------------------------------------------------------------------------
//
// Holds format 2.
//
// -----------------------------------------------------------------------------
- (void) parseHolds2
{
	[Debug log: @"Parsing holds (format 2)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"<div.*?class=\"trunc-title-line\".*?>(.*?)</div>",	@"title",
		@"<h6.*?class=\"holds-wait-position\".*?>(.*?)</h6>",	@"queueDescription",
		nil
	];
	
	[scanner scanPassString: @"<h4>Holds</h4>"];
	
	NSMutableArray *rows = [NSMutableArray array];
	if ([scanner scanNextElementWithName: @"ul" intoElement: &element])
	{
		scanner = element.scanner;
		while ([scanner scanNextElementWithName: @"li" intoElement: &element])
		{
			[Debug logDetails: element.value withSummary: @"Parsing row"];
			NSMutableDictionary *row = [[[element.scanner dictionaryUsingRegexMapping: mapping] mutableCopy] autorelease];
			[rows addObject: row];
		}
	}
	
	[self addEBookHolds: rows];
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	[browser go: catalogueURL];
	
	if ([browser clickFirstLink: [self logoutLinkLabels]])
	{
		[Debug logError: @"Logged out"];
		[browser go: catalogueURL];
	}
		
	// Find the account page link.  There a many potential link names so
	// try them all until one matches
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return NO;
	}
	
	NSMutableDictionary *authenticationAttributes = self.authenticationAttributes;
	
	// Overdive sites can support many libraries
	NSString *library = [properties objectForKey: @"Library"];
	NSString *libraryCardILS;
	if (library && [library isEqualToString: @""] == NO)
	{
		[Debug log: @"Selecting library [%@]", library];

		URL *url;
		while ((url = [browser linkForLabel: library]) != nil)
		{
			if ([[url absoluteString] hasSubString: @"MyAccount.htm"])
			{
				[browser go: url];
				break;
			}
			
			url = nil;
		}
		
		if (url == nil)
		{
			[Debug logError: @"Can't find link for your library"];
			return NO;
		}
		
		// Find select value
		HTMLElement *element;
		if ([browser.scanner scanNextElementWithName: @"option" attributeKey: @"selected" attributeValue: @"selected" intoElement: &element])
		{
			libraryCardILS = [element.attributes objectForKey: @"value"];
		}
		[browser.scanner scanPassHead];
	}

	URL *myAccountURL = [browser linkToSubmitFormNamed: @"AUTO" entries: authenticationAttributes];
	
	// Some libraries have LibraryCardILS has a hidden field but others need to
	// get it from the selected value
	if ([myAccountURL.attributes objectForKey: @"LibraryCardILS"] == nil)
	{
		[myAccountURL.attributes setObject: libraryCardILS forKey: @"LibraryCardILS"];
	}
	
	return myAccountURL;
}

// -----------------------------------------------------------------------------
//
// The page to download holds from.
//
// -----------------------------------------------------------------------------
- (URL *) downloadHoldsURL
{
	[NSScannerSettings sharedSettings].ignoreHTMLScripts = YES;
	
	URL *myAccountURL = [self myAccountURL];
	[browser go: myAccountURL];
	return [browser linkForLabel: @"My Waiting List"];
}

// -----------------------------------------------------------------------------
//
// The various account link labels.
//
// -----------------------------------------------------------------------------
- (NSArray *) accountLinkLabels
{
	return [NSArray arrayWithObjects:
		@"My Account",
		@"My Digital Account",
		@"My Media Account",
		@"Account",
		nil
	];
}

// -----------------------------------------------------------------------------
//
// The various log out link labels.
//
// -----------------------------------------------------------------------------
- (NSArray *) logoutLinkLabels
{
	return [NSArray arrayWithObjects:
		@"Logout",
		@"log out",
		@"Sign Out",
		nil
	];
}

// -----------------------------------------------------------------------------
//
// The various loan page link labels.
//
// -----------------------------------------------------------------------------
- (NSArray *) loansLinkLabels
{
	return [NSArray arrayWithObjects:
		@"My Bookshelf",
		@"Visit your Bookshelf to manage your titles",
		nil
	];
}

// -----------------------------------------------------------------------------
//
// The various holds page link labels.
//
// -----------------------------------------------------------------------------
- (NSArray *) holdsLinkLabels
{
	return [NSArray arrayWithObjects:
		@"My Waiting List",
		nil
	];
}

@end