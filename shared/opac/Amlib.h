#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface Amlib : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseLoans2;
- (void) parseHolds1;
- (void) parseHolds2;

@end