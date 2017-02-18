// =============================================================================
//
// Spydus catalogue system.
//
// Notes:
//		* Overdue loans are on a separate page but also listed on the main loans page.
//		* Holds ready for pickup are on a separate page.
//		* Need to logout first.
//
// =============================================================================

#import "Spydus.h"
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import "ModalAlert.h"
#endif

@implementation Spydus

- (BOOL) update
{
	URL *logoutURL	= [catalogueURL URLWithPath: @"/cgi-bin/spydus.exe/PGM/OPAC/CCOPT/LB/3?RDT=/spydus.html"];
	URL *accountURL	= [catalogueURL URLWithPath: @"/cgi-bin/spydus.exe/MSGTRN/OPAC/LOGINB"];
	[browser go: logoutURL];
	[browser go: accountURL];
	
	// Log in
	if ([browser submitFormNamed: @"frmLogin" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	// Deal with an "Allow Cookies" prompt.  This was first discovered on Hampshire library
	if ([browser.scanner scanPassString: @"ALLOWCOOKIES"])
	{
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
		ModalAlert *alert		= [[[ModalAlert alloc] init] autorelease];
		alert.alertView.title	= @"Accept Cookies";
		alert.alertView.message	= @"This app needs to use cookies to log in and retrieve you library data.  Tap Accept to allow cookies.";
		
		[alert.alertView addButtonWithTitle: @"Accept"];
		[alert.alertView addButtonWithTitle: @"Cancel"];
		if ([alert showModal] != 0)
		{
			[Debug logError: @"User did not accept cookies"];
			return NO;
		}
#endif
	
		[Debug log: @"Accepting cookies"];
		[browser.scanner scanPassHead];
		
		NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys: @"1", @"ACALLOWCOOKIES", nil];
		if ([browser submitFormNamed: nil entries: attributes] == NO)
		{
			[Debug logError: @"Failed to accept cookies"];
		}
	}
	
	URL *loansURL				= [browser linkForLabel: @"Current loans"];
//	URL *overdueLoansURL		= [browser linkForLabel: @"Overdue loans"];
	URL *holdsReadyForPickupURL = [browser linkForLabel: @"Reservations available for pickup"];
	URL *holdsURL				= [browser linkForLabel: @"Reservations not yet available"];

	// To test the paged output
	// loansURL = [URL URLWithString: [[loansURL absoluteString] stringByReplacingOccurrencesOfString: @"RECS=30" withString: @"RECS=2"]];

	// Loans
//	loansURL = [Test fileURLFor: @"Spydus/20051101_coffs_loans.html"];
//	loansURL = [Test fileURLFor: @"Spydus/20110122_hamilton_loans.html"];
	if (loansURL)
	{
		[browser go: loansURL];
		[self parseLoans1Page: 1];
	}

	// Overdue loans <-- not needed because overdue loans are in normal loans page
//	if (overdueLoansURL)
//	{
//		[browser go: overdueLoansURL];
//		[self parseLoans1Page: 1];
//	}

	// Holds ready for pickup
	if (holdsReadyForPickupURL)
	{
		[browser go: holdsReadyForPickupURL];
		[self parseHoldsReadyForPickup1: YES page: 1];
	}

	// Holds not yet available            
//	holdsURL = [Test fileURLFor: @"Spydus/20110430_hampshire_holds.html"];
//	holdsURL = [Test fileURLFor: @"Spydus/20111001_hamilton_holds.html"];
	if (holdsURL)
	{
		[browser go: holdsURL];
		[self parseHoldsReadyForPickup1: NO page: 1];
	}
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Loans
//
// -----------------------------------------------------------------------------
- (void) parseLoans1Page: (NSInteger) page
{
	[Debug log: @"Parsing loans (page [%d], format 1)", page];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	while ([scanner scanNextElementWithName: @"table" regexValue: @"BIBENQ" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseLoanTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		[self addLoans: rows];
		
		if (loansCount > 0) break;
	}
	
	// Look for the next page link
	[scanner scanPassHead];
	if (page < 100 && [scanner scanNextElementWithName: @"div" attributeKey: @"class" attributeValue: @"resultPages" intoElement: &element recursive: YES])
	{
		NSString *href = [element.scanner linkForLabel: @"Next"];
		if (href)
		{
			[Debug log: @"Found next page link [%@]", href];
			[browser go: [browser.currentURL URLWithPath: href]];
			[self parseLoans1Page: page + 1];
		}
	}
}

// -----------------------------------------------------------------------------
//
// Holds
//
// -----------------------------------------------------------------------------
- (void) parseHoldsReadyForPickup1: (BOOL) readyForPickup page: (NSInteger) page
{
	[Debug log: @"Parsing holds (page [%d], format 1)", page];
	NSScanner *scanner		= browser.scanner;
	HTMLElement *element	= nil;

	[scanner scanPassHead];
	
	[NSScannerSettings sharedSettings].columnCountMustMatch = NO;

	// Holds ready for pickup
	//
	//		* Look for BIBENQ in the table.
	//		* nz.HamiltonCityLibraries has links with BIBENQ so we need to search
	//		  for BIBENQ/\\d so we can make things like:
	//		  /cgi-bin/spydus.exe/ENQ/OPAC/BIBENQ/410263?QRY=...
	while ([scanner scanNextElementWithName: @"table" regexValue: @"BIBENQ/\\d" intoElement: &element])
	{
		NSArray *columns	= [element.scanner analyseHoldTableColumns];
		NSArray *rows		= [element.scanner tableWithColumns: columns];
		
		if (readyForPickup)	[self addHoldsReadyForPickup: rows];
		else				[self addHolds:               rows];
		
		if (loansCount > 0) break;
	}
	
	// Look for the next page link
	[scanner scanPassHead];
	if (page < 100 && [scanner scanNextElementWithName: @"div" attributeKey: @"class" attributeValue: @"resultPages" intoElement: &element recursive: YES])
	{
		NSString *href = [element.scanner linkForLabel: @"Next"];
		if (href)
		{
			[Debug log: @"Found next page link [%@]", href];
			[browser go: [browser.currentURL URLWithPath: href]];
			[self parseLoans1Page: page + 1];
		}
	}
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
- (URL *) myAccountURL
{
	URL *logoutURL	= [catalogueURL URLWithPath: @"/cgi-bin/spydus.exe/PGM/OPAC/CCOPT/LB/3?RDT=/spydus.html"];
	URL *accountURL	= [catalogueURL URLWithPath: @"/cgi-bin/spydus.exe/MSGTRN/OPAC/LOGINB"];
	[browser go: logoutURL];
	[browser go: accountURL];
	
	return [browser linkToSubmitFormNamed: @"frmLogin" entries: self.authenticationAttributes];
}

@end