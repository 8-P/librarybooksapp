#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface Evergreen : OPAC <OPAC>
{
	NSString *authToken;
	NSString *userID;
	NSString *thread;
}

- (void) parseLoans1;
- (void) parseHolds1;

- (id) requestService: (NSString *) service method: (NSString *) method path: (NSString *) path param: (id) param;
- (id) requestService: (NSString *) service method: (NSString *) method path: (NSString *) path params: firstParam, ...;
- (id) osrfRequestService: (NSString *) service method: (NSString *) method path: (NSString *) path params: firstParam, ...;

@end