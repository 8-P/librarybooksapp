#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface ADISBMS : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHoldsReadyForPickup1: (BOOL) readyForPickup;

@end