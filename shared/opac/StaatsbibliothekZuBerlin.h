#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface StaatsbibliothekZuBerlin : OPAC <OPAC>

- (void) parseHoldsReadyForPickup1: (BOOL) ready;

@end
