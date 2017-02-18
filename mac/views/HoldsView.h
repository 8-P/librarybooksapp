#import <Cocoa/Cocoa.h>
#import "Hold.h"

@interface HoldsView : NSView
{
	NSTextField *queuePositionLabel;
	NSImageView *dot;
	NSTextField *titleLabel;

	NSString	*queuePosition;
	NSString	*title;
	NSString	*author;
	NSString	*pickupAt;
	NSString	*queueDescription;
	BOOL		readyForPickup;
	NSDate		*expiryDate;
}

@property(retain)	NSString	*queuePosition;
@property(retain)	NSString	*title;
@property(retain)	NSString	*author;
@property(retain)	NSString	*pickupAt;
@property(retain)	NSString	*queueDescription;
@property			BOOL		readyForPickup;
@property(retain)	NSDate		*expiryDate;

- (void) setHold: (Hold *) hold;
- (void) adjustHeightForTextField: (NSTextField *) textLabel;

@end