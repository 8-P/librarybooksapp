#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface Millenium : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHolds1;

@end