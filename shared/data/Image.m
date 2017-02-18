#import "Image.h"
#import "GoogleBookSearch.h"
#import "DataStore.h"
#import "SharedExtras.h"

static const float ThumbnailWidth	= 39;
static const float ThumbnailHeight	= 43;

@implementation Image

@dynamic thumbnail, uri;

+ (Image *) image
{
	NSManagedObjectContext *context = [DataStore sharedDataStore].managedObjectContext;
	return [NSEntityDescription insertNewObjectForEntityForName: @"Image" inManagedObjectContext: context]; 
}

+ (Image *) imageForLoan: (Loan *) loan
{
	return [Image imageForTitle: loan.title author: loan.author isbn: loan.isbn];
}

+ (Image *) imageForHold: (Hold *) hold
{
	return [Image imageForTitle: hold.title author: hold.author isbn: hold.isbn];
}

// Private methods =============================================================

// -----------------------------------------------------------------------------
//
// Lookup the image.
//
// -----------------------------------------------------------------------------
+ (Image *) imageForTitle: (NSString *) title author: (NSString *) author isbn: (NSString *) isbn
{
	GoogleBookSearch *googleBookSearch = [GoogleBookSearch googleBookSearch];
	
	URL *url		= [googleBookSearch searchURLForTitle: title author: author isbn: isbn];
	NSString *uri	= [url absoluteString];

	// See if the image is cached
	DataStore *dataStore	= [DataStore sharedDataStore];
	Image *image			= [dataStore selectImageForURI: uri];

	// If the image doesn't exist download the image using NSOperation
	if (image == nil && [[[NSUserDefaults standardUserDefaults] objectForKey: @"BookCovers"] boolValue])
	{
		image		= [Image image];
		image.uri	= uri;
	}

	return image;
}

- (void) downloadImage
{
	GoogleBookSearch *googleBookSearch	= [GoogleBookSearch googleBookSearch];
	URL *url							= [URL URLWithString: self.uri];
	ImageBridge *googleImage			= [googleBookSearch imageForURL: url];
	
	if (googleImage)
	{
		self.thumbnail = [googleImage thumbnailWithSize: CGSizeMake(ThumbnailWidth, ThumbnailHeight)];
		[[DataStore sharedDataStore] save];
	}
}

@end