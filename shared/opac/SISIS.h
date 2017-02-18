#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface SISIS : OPAC <OPAC>
{
}

- (void) parseLoans1Page: (NSInteger) page;
- (void) parseHolds1;

@end