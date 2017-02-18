#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface NEBIS : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHolds1;

@end