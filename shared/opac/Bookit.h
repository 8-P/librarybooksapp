#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface Bookit : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHolds1;
- (NSString *) inUserId: (URL *) baseURL;
- (URL *) baseURL;

@end