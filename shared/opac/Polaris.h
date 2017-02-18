#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface Polaris : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHolds1;

@end