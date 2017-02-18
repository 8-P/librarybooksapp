// =============================================================================
//
// Yarra Plenty Regional Library
//
//		* Implements Renew Items menu item.  Note that this menu item is only
//		  implemented for a few libraries.
//		* Stopped using this when YPRL switched to BiblioCommons on 18 Nov 2010.
//
// =============================================================================

#import "YarraPlentyRegionalLibrary.h"

@implementation YarraPlentyRegionalLibrary

// -----------------------------------------------------------------------------
//
// Renew Items link.
//
// -----------------------------------------------------------------------------
- (URL *) renewItemsURL
{
	[browser go: myAccountCatalogueURL];
	
	if ([browser clickFirstLink: [self accountLinkLabels]] == NO)
	{
		[Debug logError: @"Can't find account page link"];
		return nil;
	}
	
	if ([browser clickLink: @"Renew My Materials"] == NO)
	{
		[Debug logError: @"Can't find renew materials page link"];
		return nil;
	}
	
	return [browser linkToSubmitFormNamed: @"accessform" entries: self.authenticationAttributes];
}

@end