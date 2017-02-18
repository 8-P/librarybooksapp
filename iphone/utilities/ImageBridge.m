// =============================================================================
//
// Desktop implementation of the image handling.
//
// =============================================================================

#import "ImageBridge.h"
#import "UIImageExtras.h"

static const float JPEGImageCompressionQuality	= 1.0;

@implementation ImageBridge

@synthesize image;

+ (ImageBridge *) imageWithData: (NSData *) data
{
	return [[[ImageBridge alloc] initWithData: data] autorelease];
}

- (id) initWithData: (NSData *) data
{
	self = [super init];
	image = [[UIImage alloc] initWithData: data];
	return self;
}

- (void) dealloc
{
	[image release];
	[super dealloc];
}

- (NSData *) thumbnailWithSize: (CGSize) size
{
	UIImage *thumbnail	= [self.image imageByScalingAndCroppingToSize: size];
	return UIImageJPEGRepresentation(thumbnail, JPEGImageCompressionQuality);
}

@end