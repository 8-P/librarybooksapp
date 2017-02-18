#import <UIKit/UIKit.h>

@interface LBTouchAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate>
{
    UIWindow			*window;
    UITabBarController	*tabBarController;
	UIView				*migrationView;
}

@property (nonatomic, retain) IBOutlet UIWindow				*window;
@property (nonatomic, retain) IBOutlet UITabBarController	*tabBarController;
@property (nonatomic, retain) IBOutlet UIView				*migrationView;

- (void) reloadBadges: (id) sender;
- (void) restoreLastSelectedTab;
- (void) migrateThenLoadMainApplication;
- (void) loadMainApplication;
- (void) autoUpdateCheck;

@end