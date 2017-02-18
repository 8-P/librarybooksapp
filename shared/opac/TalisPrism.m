// =============================================================================
//
// TalisPrism
//
// =============================================================================

#import "TalisPrism.h"

@implementation TalisPrism

- (BOOL) update
{
	[browser go: [catalogueURL URLWithPath: @"/TalisPrism/logout.do"]];
	[browser go: [catalogueURL URLWithPath: @"/TalisPrism/accessAccount.do"]];
	
	if ([browser go: [self linkToSubmitForm]] == NO)
	{
		[Debug log: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
//	[browser go: [Test fileURLFor: @"TalisPrism/20110528_queensuni_loans.html"]];
//	[browser go: [Test fileURLFor: @"TalisPrism/20110925_unicollegedublin.html"]];
	[self parseLoans1];
	if (loansCount == 0) [self parseLoans2];
	[self parseHolds1];
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Loans.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	if ([scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"loans"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element]
		&& [element.scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addLoans: rows];
	}
}

- (void) parseLoans2
{
	[Debug log: @"Parsing loans (format 2)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	if ([scanner scanPassElementWithName: @"a" attributeKey: @"name" attributeValue: @"loans"]
		&& [scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addLoans: rows];
	}
}

// -----------------------------------------------------------------------------
//
// Holds.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];

	scannerSettings.holdColumnsDictionary = [OrderedDictionary dictionaryWithObjectsAndKeys:
		@"pickUpAt",	@"Collection Site",
		nil
	];
	
	if ([scanner scanNextElementWithName: @"table" regexValue: @"<a name=\"reservations\"" intoElement: &element]
		&& [element.scanner scanNextElementWithName: @"table" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addHolds: rows];
	}
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
#if 0
- (URL *) myAccountURL
{
	[browser go: [catalogueURL URLWithPath: @"/TalisPrism/logout.do"]];
	[browser go: [catalogueURL URLWithPath: @"/TalisPrism/accessAccount.do"]];
	
	URL *url					= [self linkToSubmitForm];
	return url;
	
//	NSDictionary *attributes	= url.attributes;
//	url.attributes				= nil;
//	
//	return [url URLWithPathFormat: @"/TalisPrism/logon.do;jsessionid=%@?talissession=%@",
//		[attributes objectForKey: @"jsessionid"], [[attributes objectForKey: @"talissession"] URLEncode]];
}
#endif

// -----------------------------------------------------------------------------
//
// Handle the special login form.
//
//		* The username and password are not sent but encoded using a challenge
//		  key (alpha).
//
// -----------------------------------------------------------------------------
- (URL *) linkToSubmitForm
{
	NSString *jsessionid;
	if ([browser.scanner scanFromString: @"var jSessionId=\"" upToString: @"\"" intoString: &jsessionid] == NO)
	{
		[Debug logError: @"Failed to find jsessionid"];
		return nil;
	}
	
	NSString *alpha;
	if ([browser.scanner scanFromString: @"var alpha=\"" upToString: @"\"" intoString: &alpha] == NO)
	{
		[Debug logError: @"Failed to find alpha challenge key"];
		return nil;
	}
	
	URL *login = [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
	if (login == NO)
	{
		[Debug log: @"Failed to find login form"];
		return nil;
	}
	
	NSMutableDictionary *attributes = [[login.attributes mutableCopy] autorelease];
	[attributes setObject: jsessionid forKey: @"jsessionid"];
	[attributes setObject: [self sessionForAlpha: alpha] forKey: @"talissession"];
	[attributes removeObjectForKey: @"hidden_username"];
	[attributes removeObjectForKey: @"hidden_password"];
	login.attributes = attributes;
	
	return login;
}

// -----------------------------------------------------------------------------
//
// This is an implementation of Talis' normalise() function.
//
//		* The TalisPrism system uses a challenge and response to log in.
//		* If the the password is not required it is subsituted with an empty
//		  string.
//
// -----------------------------------------------------------------------------
- (NSString *) sessionForAlpha: (NSString *) alpha
{
	NSString *username = [self.authenticationAttributes objectForKey: @"hidden_username"];
	NSString *password = [self.authenticationAttributes objectForKey: @"hidden_password"];

	NSString *text = [NSString stringWithFormat: @"%@:%@",
		(username) ? username : @"",
		(password) ? password : @""
	];

	NSMutableString *session = [NSMutableString string];

	for (int i = 0; i < [text length]; i++)
	{
		int randomIndex = floor((float) random() / RAND_MAX * [alpha length]);
		int alphaIndex	= [alpha rangeOfString: [NSString stringWithFormat: @"%C", [text characterAtIndex: i]]].location;
		int fudgedIndex = (alphaIndex + randomIndex) % [alpha length];
		
		[session appendFormat: @"%C%C", [alpha characterAtIndex: fudgedIndex],
			[alpha characterAtIndex: randomIndex]];
	}
	
	return session;
}

@end