#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface SIRSI : OPAC <OPAC>
{
}

- (void) parse;

- (void) parseLoans1;
- (void) parseLoans2;
- (void) parseLoans3;
- (void) parseLoans4;

- (void) parseHolds1;
- (void) parseHolds4;
- (void) parseHolds5;

- (NSArray *) accountLinkLabels;
- (NSArray *) reviewLinkLabels;

@end