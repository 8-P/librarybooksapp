#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface BiblioCommons : OPAC <OPAC>
{
}

- (void) parseLoans1Page: (NSInteger) page;
- (void) parseHolds1Page: (NSInteger) page;

@end