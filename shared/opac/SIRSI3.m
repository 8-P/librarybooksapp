// =============================================================================
//
// SIRSI 3
//
//		1. Click on account page link
//		2. Get login prompt
//		3. Click checkouts link
//
// =============================================================================

#import "SIRSI3.h"

@implementation SIRSI3

- (BOOL) update
{
	[browser go: catalogueURL];
	
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return NO;
	}
	
	if ([browser submitFormNamed: @"AUTO" entries: self.authenticationAttributes] == NO)
	{
		[Debug logError: @"Failed to login"];
		return NO;
	}
	[self authenticationOK];
	
	// Find the link to the checkouts page
	if ([browser clickFirstLink: [self reviewLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find review checkouts page link"];
		return NO;
	}

	[self parseLoans1];
	if (loansCount == 0) [self parseLoans2];
	if (loansCount == 0) [self parseLoans3];
	[self parseHolds1];
	
	return YES;
}

- (URL *) myAccountURL
{
	[browser go: myAccountCatalogueURL];
	
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return nil;
	}

	return [browser linkToSubmitFormNamed: @"AUTO" entries: self.authenticationAttributes];
}

@end