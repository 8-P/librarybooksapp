#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface VuFind : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHolds1;

@end