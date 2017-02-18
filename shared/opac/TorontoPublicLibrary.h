#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface TorontoPublicLibrary : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHolds1;

@end