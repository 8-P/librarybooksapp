// =============================================================================
//
// Santa Clara County Library has a redirect page.  The library properties
// points to the redirect page.  We use the redirect location as the catalogue
// URL.
//
// =============================================================================

#import "SantaClaraCountyLibrary.h"

@implementation SantaClaraCountyLibrary

- (BOOL) update
{
	[browser go: catalogueURL];
	self.catalogueURL = browser.currentURL;
	
	return [super update];
}

@end