#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface Overdrive : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHolds1;

@end