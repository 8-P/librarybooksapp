// =============================================================================
//
// Evergreen
//
//		* AJAX API.
//		* Horribly complex.
//		* Based on OWWL system.
//
// =============================================================================

#import "Evergreen2.h"

@implementation Evergreen2

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
		username,				@"username",
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
		path: @"/0/__p/27" params: authToken, [NSNumber numberWithInteger: 1], nil];
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

// -----------------------------------------------------------------------------
//
// Loans.
//
//		* Get list of loans.  Then for each loan:
//			* Get hold title/author.
//
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];
	
	NSDictionary *checkouts = [self requestService: @"open-ils.actor" method: @"open-ils.actor.user.checked_out"
		path: @"/0" params: authToken, userID, nil];
	
	NSMutableArray *recordIDs = [NSMutableArray array];
	[recordIDs addObjectsFromArray: [checkouts objectAtPath: @"/out"]];
	[recordIDs addObjectsFromArray: [checkouts objectAtPath: @"/claims_returned"]];
	[recordIDs addObjectsFromArray: [checkouts objectAtPath: @"/long_overdue"]];
	[recordIDs addObjectsFromArray: [checkouts objectAtPath: @"/overdue"]];
	[recordIDs addObjectsFromArray: [checkouts objectAtPath: @"/lost"]];

	NSMutableArray *loans = [NSMutableArray array];
	for (NSArray *recordID in recordIDs)
	{
		NSArray *loanRecord = [self requestService: @"open-ils.circ" method: @"open-ils.circ.retrieve"
			path: @"/0/__p" params: authToken, recordID, nil];
		if (loanRecord == nil || [loanRecord isKindOfClass: [NSArray class]] == NO)
		{
			[Debug logError: @"Failed to download loan record"];
			continue;
		}

		NSNumber *biblioID = [loanRecord objectAtPath: @"/20"];
		NSArray *biblioRecord = [self requestService: @"open-ils.search" method: @"open-ils.search.biblio.mods_from_copy"
			path: @"/0/__p" param: biblioID];
		if (biblioRecord == nil || [biblioRecord isKindOfClass: [NSArray class]] == NO)
		{
			[Debug logError: @"Failed to download biblio record"];
			continue;
		}
		
		NSDictionary *loan = [NSDictionary dictionaryWithObjectsAndKeys:
			[biblioRecord objectAtPath: @"/0"],	@"title",
			[biblioRecord objectAtPath: @"/1"],	@"author",
			[loanRecord   objectAtPath: @"/6"],	@"dueDate",
			nil];
		[loans addObject: loan];
	}
	
	[self addLoans: loans];
}

// -----------------------------------------------------------------------------
//
// Holds.
//
//		* Get list of holds.  Then for each hold:
//			* Get hold title/author.
//			* Get hold status.
//
//	Not implemented:
//		
//		* Pickup location.  Need to get lookup table from .js file.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];

	NSArray *holdRecords = [self requestService: @"open-ils.circ" method: @"open-ils.circ.holds.retrieve"
		path: @"/0" params: authToken, userID, nil];

	NSMutableArray *holds = [NSMutableArray array];
	for (NSArray *holdRecord in holdRecords)
	{
		if ([holdRecord isKindOfClass: [NSDictionary class]] == NO) continue;
	
		NSNumber *recordLookupID	= [holdRecord objectAtPath: @"/__p/20"];
		NSString *recordType		= [holdRecord objectAtPath: @"/__p/9"];
		NSNumber *statusLookupID	= [holdRecord objectAtPath: @"/__p/11"];
		
		// Get the biblio record
		//		* Need to look at the record type:
		//			M			= meta record
		//			otherwise	= normal record		
		NSString *method = ([recordType isEqualToString: @"M"])
			? @"open-ils.search.biblio.metarecord.mods_slim.retrieve"
			: @"open-ils.search.biblio.record.mods_slim.retrieve";
			
		NSArray *biblioRecord = [self requestService: @"open-ils.search" method: method
			path: @"/0/__p" param: recordLookupID];
		if (biblioRecord == nil || [biblioRecord isKindOfClass: [NSArray class]] == NO)
		{
			[Debug logError: @"Failed to download biblio record"];
			continue;
		}
		
		// Get the status
		NSDictionary *holdStatus = [self requestService: @"open-ils.circ" method: @"open-ils.circ.hold.status.retrieve"
			path: @"/0" params: authToken, statusLookupID, nil];
		
		NSNumber *status		= [holdStatus objectAtPath: @"/status"];
		NSNumber *queuePosition = [holdStatus objectAtPath: @"/position"];
		
		NSString *queueDescription = @"";
		if (status)
		{
			if      ([status integerValue]  < 3) queueDescription = @"Waiting for copy";
			else if ([status integerValue] == 3) queueDescription = @"In Transit";
			else if ([status integerValue] == 4) queueDescription = @"Ready for Pickup";
		}
		
		NSDictionary *hold = [NSDictionary dictionaryWithObjectsAndKeys:
			[biblioRecord objectAtPath:  @"/0"],	@"title",
			[biblioRecord objectAtPath:  @"/1"],	@"author",
			queueDescription,						@"queueDescription",
			queuePosition,							@"queuePosition",
			nil];
		[holds addObject: hold];
	}
	
	[self addHolds: holds];
}

// -----------------------------------------------------------------------------
//
// The account page URL.
//
// -----------------------------------------------------------------------------
#if 0
- (URL *) myAccountURL
{
}
#endif

@end