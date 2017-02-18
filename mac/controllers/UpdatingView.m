// =============================================================================
//
// NSMenuItem view that displays the words "Updating" and a spinning progress
// indicator to the right.
//
//		* Displayed when the menu is updating.
//
// =============================================================================

#import "UpdatingView.h"
#import <QuartzCore/QuartzCore.h>
#import "NSTextFieldExtras.h"

#define MARGIN_LEFT		19
#define MARGIN_RIGHT	8
#define IMAGE_HEIGHT	18
#define IMAGE_WIDTH		18

@implementation UpdatingView

+ (UpdatingView *) updatingViewWithWidth: (CGFloat) width
{
	return [[[UpdatingView alloc] initWithFrame: NSMakeRect(0, 0, width, 19)] autorelease];
}

- (id) initWithFrame: (NSRect) frame
{
    self = [super initWithFrame: frame];
    if (self)
	{
		[self setAutoresizingMask: NSViewWidthSizable];
    }
    
    return self;
}

- (void) dealloc
{
	[_textField release];
	[_imageView release];
	[super dealloc];
}

- (void) drawRect: (NSRect) frame
{
	CGFloat w = frame.size.width;
	CGFloat h = frame.size.height;

	if (_textField == nil)
	{
		_textField = [[NSTextField tinyLabelWithFrame: NSMakeRect(MARGIN_LEFT + IMAGE_WIDTH, 2, w - MARGIN_LEFT - IMAGE_WIDTH - MARGIN_RIGHT, h - 5)] retain];
		
		[_textField setTextColor:			[NSColor disabledControlTextColor]];
		[_textField setAutoresizesSubviews:	YES];
		[_textField setAutoresizingMask:	NSViewMinXMargin];
		[_textField setStringValue:			@"UPDATING"];
		
		[self addSubview: _textField];
	}
	
	if (_imageView == nil)
	{
		_imageView = [[NSImageView alloc] initWithFrame: NSMakeRect(MARGIN_LEFT, 1, IMAGE_WIDTH, IMAGE_HEIGHT)];
		_imageView.wantsLayer = YES;
		_imageView.imageAlignment = NSImageAlignCenter;
		_imageView.image = [NSImage imageNamed: NSImageNameRefreshFreestandingTemplate];
		[_imageView setEnabled: NO];

		[self addSubview: _imageView];
	}
	
	_imageView.layer.anchorPoint	= CGPointMake(0.5, 0.5);
	_imageView.layer.position		= CGPointMake(IMAGE_WIDTH/2, IMAGE_HEIGHT/2);
}


// -----------------------------------------------------------------------------
//
// This view gets used in a NSMenuItem so we need to start animation only when
// the menu item is display.
//
// http://stackoverflow.com/questions/4671017/using-nsprogressindicator-inside-an-nsmenuitem
//
// -----------------------------------------------------------------------------
- (void) viewWillDraw
{
	[self performSelector: @selector(startAnimation) withObject: nil
		afterDelay: 0 inModes: @[NSEventTrackingRunLoopMode]];
}

- (void) startAnimation
{
	if (_imageView.layer.animationKeys == nil || [_imageView.layer.animationKeys indexOfObject: @"spinAnimation"] == NSNotFound)
	{
		CABasicAnimation *animation		= [CABasicAnimation animationWithKeyPath: @"transform.rotation.z"];
		animation.duration				= 0.3;
		animation.toValue				= [NSNumber numberWithFloat: -M_PI / 2];
		animation.repeatCount			= INFINITY;
		animation.cumulative			= YES;
		animation.removedOnCompletion	= YES;
		
		[_imageView.layer addAnimation: animation forKey: @"spinAnimation"];
	}
}

@end
