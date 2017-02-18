// =============================================================================
//
// JSON encoding and decoding.
//
// =============================================================================

#import "JSON.h"
#import "CJSONDeserializer.h"
#import "CJSONDataSerializer.h"
#import "SharedExtras.h"
#import "Debug.h"

@implementation JSON

+ (id) toJson: (NSString *) string
{
	NSError *error = nil;
	NSData *data = [string dataUsingEncoding: NSUTF32BigEndianStringEncoding];
	id json = [[CJSONDeserializer deserializer] deserialize: data error: &error];
	
	if (json == nil)
	{
		NSString *details = (error) ? [error localizedDescription] : string;
		[Debug logDetails: details withSummary: @"Error decoding JSON"];
	}
	
	return json;
}

+ (NSString *) toString: (id) json
{
	NSError *error = nil;
	NSData *data = [[CJSONDataSerializer serializer] serializeObject: json error: &error];
	
	if (data == nil)
	{
		NSString *details = (error) ? [error localizedDescription] : [json description];
		[Debug logDetails: details withSummary: @"Error encoding JSON"];
	}
	
	return [NSString stringWithData: data encoding: NSUTF8StringEncoding];
}

@end