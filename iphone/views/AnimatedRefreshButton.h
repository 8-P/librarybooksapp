#import <Foundation/Foundation.h>

@interface AnimatedRefreshButton : NSObject
{
	UIActivityIndicatorView	*activityIndicator;
	UIBarButtonItem			*button;
}

@property(retain, readonly)	UIBarButtonItem *button;

- (void) startAnimating;
- (void) stopAnimating;

@end