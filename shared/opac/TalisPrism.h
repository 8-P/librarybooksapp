#import <Foundation/Foundation.h>
#import "OPAC.h"

@interface TalisPrism : OPAC <OPAC>
{
}

- (void) parseLoans1;
- (void) parseLoans2;
- (void) parseHolds1;
- (URL *) linkToSubmitForm;
- (NSString *) sessionForAlpha: (NSString *) alpha;

@end