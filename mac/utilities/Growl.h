#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@interface Growl : NSObject <GrowlApplicationBridgeDelegate>
{
	BOOL overdueLoansVisible;
	BOOL holdsReadyVisible;
}

- (void) update;
- (void) displayOverdueLoanMessage: (NSString *) message title: (NSString *) title;
- (void) displayHoldsReadyMessage: (NSString *) message title: (NSString *) title;
+ (Growl *) sharedGrowl;

@end