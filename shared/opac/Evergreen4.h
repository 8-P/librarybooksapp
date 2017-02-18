#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface Evergreen4 : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseHolds1;
- (URL *) linkForValue: (NSString *) value;

@end