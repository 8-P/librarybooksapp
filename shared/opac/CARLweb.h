#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface CARLweb : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseOverdueLoans1;
- (void) parseHolds1;

@end