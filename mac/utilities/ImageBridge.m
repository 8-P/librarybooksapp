// =============================================================================
//
// Desktop implementation of the image handling.
//
// =============================================================================

#import "ImageBridge.h"

@implementation ImageBridge

@synthesize image;

+ (ImageBridge *) imageWithData: (NSData *) data
{
	return [[[ImageBridge alloc] initWithData: data] autorelease];
}

- (id) initWithData: (NSData *) data
{
	self = [super init];
	image = [[NSImage alloc] initWithData: data];
	return self;
}

- (void) dealloc
{
	[image release];
	[super dealloc];
}

- (NSData *) thumbnailWithSize: (CGSize) size
{
	NSSize thumnailSize = NSMakeSize(size.width, size.height);
	NSImage *thumbnailImage = [[NSImage alloc] initWithSize: thumnailSize];
	NSSize originalSize		= [self.image size];
	
	NSRect thumbnailRect = [self calculateThumbnailRect: thumnailSize originalSize: originalSize];

	[thumbnailImage lockFocus];
	[self.image drawInRect: thumbnailRect fromRect: NSMakeRect(0, 0, originalSize.width, originalSize.height) operation: NSCompositeSourceOver fraction: 1.0];
	[thumbnailImage unlockFocus];
	
	NSData *resizedData = [thumbnailImage TIFFRepresentation];
	[thumbnailImage release];
	
	return resizedData;
}

- (NSRect) calculateThumbnailRect: (NSSize) targetSize originalSize: (NSSize) originalSize
{
	NSRect rect;

	float widthFactor	= targetSize.width  / originalSize.width;
	float heightFactor	= targetSize.height / originalSize.height;
  
	float scaleFactor = 0;
	if (widthFactor > heightFactor) 
	{
		scaleFactor = widthFactor;	// Scale to fit height
	}
	else
	{
		scaleFactor = heightFactor;	// Scale to fit width
	}
	
	scaleFactor *= 1.0;
	
	rect.size.width  = originalSize.width  * scaleFactor;
	rect.size.height = originalSize.height * scaleFactor;

	// Center the image
	if (widthFactor > heightFactor)
	{
		rect.origin.y = (targetSize.height - rect.size.height) * 0.5;
	}
	else if (widthFactor < heightFactor)
	{
		rect.origin.x = (targetSize.width - rect.size.width) * 0.5;
	}

	return rect;
}

@end