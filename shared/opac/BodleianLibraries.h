#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface BodleianLibraries : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHoldsReadyForPickup1: (BOOL) readyForPickup;

@end