#import <Foundation/Foundation.h>
#import <MessageUI/MessageUI.h>

@interface DebugReporter : UIViewController <MFMailComposeViewControllerDelegate>
{
	BOOL				displayed;
	UIViewController	*view;
}

+ (DebugReporter *) sharedDebugReporter;
- (void) presentDebugReporterForView: (UIViewController *) forView;

@end