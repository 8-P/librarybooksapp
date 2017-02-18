// =============================================================================
//
// SIRSI5
//
//		1. Get login prompt
//		2. Checkouts displayed.
//
//		* Authentication parameters are non-standard (userid & pin
//		  vs user_id & password).
//
// =============================================================================

#import "SIRSI5.h"

@implementation SIRSI5

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];

//	[browser go: [Test fileURLFor: @"SIRSI/20110327_santacruz_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20110402_clevnet_loans.html"]];
//	[browser go: [Test fileURLFor: @"SIRSI/20110430_santacruz_loans.html"]];

	[self parse];
	
	return YES;
}

- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end