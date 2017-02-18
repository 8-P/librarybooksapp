#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface Spydus : OPAC <OPAC>
{
}

- (void) parseLoans1Page: (NSInteger) page;
- (void) parseHoldsReadyForPickup1: (BOOL) readyForPickup page: (NSInteger) page;

@end