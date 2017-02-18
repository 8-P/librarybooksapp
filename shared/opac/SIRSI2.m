// =============================================================================
//
// SIRSI 2
//
//		1. Get login prompt
//		2. Click on account page link
//		3. Click checkouts link
//
// =============================================================================

#import "SIRSI2.h"

@implementation SIRSI2

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	// Find the account page link
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return NO;
	}
	
	// Find the link to the checkouts page
	if ([browser clickFirstLink: [self reviewLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find review checkouts page link"];
		return NO;
	}

	[self parse];
	
	return YES;
}

- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end