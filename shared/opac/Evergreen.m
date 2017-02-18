// =============================================================================
//
// Evergreen
//
//		* AJAX API.
//		* Horribly complex.
//
// =============================================================================

#import "Evergreen.h"

@implementation Evergreen

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
		path: @"/0/__p/28" params: authToken, [NSNumber numberWithInteger: 1], nil];
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
// -----------------------------------------------------------------------------
- (void) parseLoans1
{
	[Debug log: @"Parsing loans (format 1)"];

	NSArray *records = [self osrfRequestService: @"open-ils.circ" method: @"open-ils.circ.actor.user.checked_out.atomic"
		path: @"/" params: authToken, userID, nil];

	NSMutableArray *loans = [NSMutableArray array];
	for (NSArray *record in records)
	{
		NSDictionary *loan = [NSDictionary dictionaryWithObjectsAndKeys:
			[record objectAtPath: @"/record/__p/0"],	@"title",
			[record objectAtPath: @"/record/__p/1"],	@"author",
			[record objectAtPath: @"/circ/__p/6"],		@"dueDate",
			nil
		];
		[loans addObject: loan];
	}
	
	[self addLoans: loans];
}

// -----------------------------------------------------------------------------
//
// Holds.
//
// Not implemented:
//		
//		* Pickup location.  Need to get lookup table from .js file.
//		* Ready for pickup detection.
//
// -----------------------------------------------------------------------------
- (void) parseHolds1
{
	[Debug log: @"Parsing holds (format 1)"];

	NSArray *idList = [self osrfRequestService: @"open-ils.circ" method: @"open-ils.circ.holds.id_list.retrieve"
		path: @"/" params: authToken, userID, nil];
	NSArray *records = [self osrfRequestService: @"open-ils.circ" method: @"open-ils.circ.hold.details.batch.retrieve.atomic"
		path: @"/" params: authToken, idList, nil];

	NSMutableArray *holds = [NSMutableArray array];
	for (NSArray *record in records)
	{
		// Detect ready for pickup status
		NSString *queueDescription = @"";
		NSInteger status = [[record objectAtPath: @"/status"] integerValue];
		if      (status  < 3) queueDescription = @"Waiting for copy";
		else if (status == 3) queueDescription = @"In Transit";
		else if (status == 4) queueDescription = @"Ready for Pickup";
	
		NSDictionary *hold = [NSDictionary dictionaryWithObjectsAndKeys:
			[record objectAtPath: @"/mvr/__p/0"],						@"title",
			[record objectAtPath: @"/mvr/__p/1"],						@"author",
			[[record objectAtPath: @"/queue_position"] stringValue],	@"queuePosition",
			queueDescription,											@"queueDescription",
			nil
		];
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

// -----------------------------------------------------------------------------
//
// Make a request.
//
//		* Evergreen does everything via XHR requests.
//		* Need to strip out comments like /*--S au--*/ from the JSON
//		  response as it stops the JSON decoder from working.
//		* The JSON response looks like:
//
//			{"payload": ..., "status": 200}
//			             ^               ^
//			             |               |
//			             |               `---------- Return nil if status != 200
//			             `-- Return this content based on path
//
// -----------------------------------------------------------------------------
- (id) requestService: (NSString *) service method: (NSString *) method path: (NSString *) path param: (id) param
{
	return [self requestService: service method: method path: path params: param, nil];
}

- (id) requestService: (NSString *) service method: (NSString *) method path: (NSString *) path params: firstParam, ...
{
	[Debug space];
	[Debug log: @"Request service [%@] method [%@]", service, method];
	
	va_list arguments;
	va_start(arguments, firstParam);
	
	id param;
	NSMutableArray *params = [NSMutableArray arrayWithObject: [JSON toString: firstParam]];
	while ((param = va_arg(arguments, id)) != nil)
	{
		[params addObject: [JSON toString: param]];
	}
	
	va_end(arguments);
	
	// Build the parameters
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		service,	@"service",
		method,		@"method",
		params,		@"param",
		nil
	];
	
	// Make the request
	URL *url				= [catalogueURL URLWithPath: @"/osrf-gateway-v1"];
	url.attributes			= attributes;
	NSString *jsonString	= [url download];
	
	// Decode the JSON response
	jsonString = [jsonString stringByDeletingOccurrencesOfRegex: @"/\\*.*?\\*/"];
	[browser.scanner initWithString: jsonString];
	NSDictionary *dictionary = [JSON toJson: jsonString];
	
	// Check status code
	NSNumber *status = [dictionary objectForKey: @"status"];
	if ([status integerValue] != 200)
	{
		[Debug log: @"Bad status code [%d]", [status integerValue]];
		return nil;
	}
	
	// Return just the requests path component
	id payload		= [dictionary objectForKey: @"payload"];
	id returnObject	= [payload objectAtPath: path];
	
	if (returnObject == nil)
	{
		[Debug logDetails: [payload description] withSummary: @"No element at path [%@]", path];
		return nil;
	}
	
	[Debug logDetails: [returnObject description] withSummary: @"JSON at path [%@]", path];
	return returnObject;
}

// -----------------------------------------------------------------------------
//
// Make a OSRF request.
//
//		* Need to specify the service in a custom HTTP header.
//		* Rather complex JSON request structure.
//
// -----------------------------------------------------------------------------
- (id) osrfRequestService: (NSString *) service method: (NSString *) method path: (NSString *) path params: firstParam, ...
{
	[Debug space];
	[Debug log: @"OSRF request method [%@]", method];
	
	va_list arguments;
	va_start(arguments, firstParam);
	
	id param;
	NSMutableArray *params = [NSMutableArray arrayWithObject: firstParam];
	while ((param = va_arg(arguments, id)) != nil)
	{
		[params addObject: param];
	}
	
	va_end(arguments);

	// Build the parameters
	NSDictionary *__p_payload__p = [NSDictionary dictionaryWithObjectsAndKeys:
		method,								@"method",
		params,								@"params",
		nil
	];
	NSDictionary *__p_payload = [NSDictionary dictionaryWithObjectsAndKeys:
		@"osrfMethod",						@"__c",
		__p_payload__p,						@"__p",
		nil
	];
	NSDictionary *__p = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInteger: 0],	@"threadTrace",
		@"REQUEST",							@"type",
		__p_payload,						@"payload",
		@"en-US",							@"locale",
		nil
	];
	NSArray *message = [NSArray arrayWithObject: [NSDictionary dictionaryWithObjectsAndKeys:
		@"osrfMessage",						@"__c",
		__p,								@"__p",
		nil
	]];
	NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[JSON toString: message],			@"osrf-msg",
		nil
	];

	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
		service,	@"X-OpenSRF-service",
		thread,		@"X-OpenSRF-thread",
		nil
	];
	
	// Make the request
	URL *url				= [catalogueURL URLWithPath: @"/osrf-http-translator"];
	url.attributes			= attributes;
	url.headers				= headers;
	NSString *jsonString	= [url download];
	
	// Decode the JSON response
	[browser.scanner initWithString: jsonString];
	id json = [JSON toJson: jsonString];
	
	// Return just the requests path component
	id content	= [json objectAtPath: @"/0/__p/payload/__p/content"];
	id object	= [content objectAtPath: path];
	
	if (object == nil)
	{
		[Debug logDetails: [content description] withSummary: @"No element at path [%@]", path];
		return nil;
	}

	[Debug logDetails: [object description] withSummary: @"JSON at path [%@]", path];
	return object;
}

@end