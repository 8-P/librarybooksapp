// =============================================================================
//
// Evergreen 3
//
//		* Newer version of evergreen.
//		* The authentication format is different.
//
// =============================================================================

#import "Evergreen3.h"

@implementation Evergreen3

- (BOOL) update
{
	NSString *username = libraryCard.authentication1;
	NSString *password = libraryCard.authentication2;

	// Get the seed
	NSString *seed =  [self requestService: @"open-ils.auth" method: @"open-ils.auth.authenticate.init"
		path: @"/0" param: username];
	if (seed == nil)
	{
		[Debug logError: @"Failed to authenticate at open-ils.auth.authenticate.init"];
		return NO;
	}
	
	// Send the encoded password using the seed
	NSString *passwordHash = [[seed stringByAppendingString: [password md5AsLowerCaseHex]] md5AsLowerCaseHex];
	NSDictionary *json = [NSDictionary dictionaryWithObjectsAndKeys:
		passwordHash,			@"password",
		@"opac",				@"type",
		[NSNull null],			@"org",
		username,				@"barcode",
		nil
	];
	authToken = [self requestService: @"open-ils.auth" method: @"open-ils.auth.authenticate.complete"
		path: @"/0/payload/authtoken" param: json];
	[self authenticationOK];
	if (authToken == nil)
	{
		[Debug logError: @"Failed to authenticate at open-ils.auth.authenticate.complete"];
		return NO;
	}
		
	// Get the user ID
	userID = [self requestService: @"open-ils.auth" method: @"open-ils.auth.session.retrieve"
		path: @"/0/userobj/__p/28" params: authToken, [NSNumber numberWithInteger: 1], nil];
	if (userID == nil)
	{
		[Debug logError: @"Failed to authenticate at open-ils.auth.session.retrieve stage"];
		return NO;
	}
	
	// Create a random thread value for the OSRF requests
	thread = [NSString stringWithFormat: @"%d.%ld", rand(), time(NULL)];
	
	[self parseLoans1];
	[self parseHolds1];

	return YES;
}

@end