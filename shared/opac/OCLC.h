#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface OCLC : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseLoans2;
- (void) parseHolds1;

@end