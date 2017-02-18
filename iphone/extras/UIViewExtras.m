#import "UIViewExtras.h"

@implementation UIView (UIViewExtras)

// -----------------------------------------------------------------------------
//
// Adds an overlay view.  Used by the loans, holds and history views to display
// the "No Loans" etc view.
//
// -----------------------------------------------------------------------------
- (void) addOverlayView: (UIView *) view
{
	// Only add the view once
	if ([view isDescendantOfView: self] == NO)
	{
		[self addSubview: view];
	}
}

// -----------------------------------------------------------------------------
//
// Remove the overlay view.
//
// -----------------------------------------------------------------------------
- (void) removeOverlayView: (UIView *) view
{
	[view removeFromSuperview];
}

@end
