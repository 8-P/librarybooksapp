#import <UIKit/UIKit.h>
#import "URL.h"

@interface WebViewController : UIViewController
{
	UIBarButtonItem *zoomButton;
}

@property (retain) URL *url;

@end