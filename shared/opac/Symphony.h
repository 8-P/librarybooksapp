#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface Symphony : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHolds1;

@end