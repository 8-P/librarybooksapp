#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface PhoenixPublicLibrary : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHoldsReadyForPickup1: (BOOL) readyForPickup;

@end