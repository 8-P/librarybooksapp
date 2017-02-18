#import "UIImageExtras.h"

@implementation UIImage (UIImageExtras)

// -----------------------------------------------------------------------------
//
// Copied from http://iphonedevbook.com/forum/viewtopic.php?f=25&t=661
//
// -----------------------------------------------------------------------------
- (UIImage *) imageByScalingAndCroppingToSize: (CGSize) targetSize
{
   UIImage *sourceImage		= self;
   UIImage *newImage		= nil;        
   CGSize imageSize			= sourceImage.size;
   CGFloat width			= imageSize.width;
   CGFloat height			= imageSize.height;
   CGFloat targetWidth		= targetSize.width;
   CGFloat targetHeight		= targetSize.height;
   CGFloat scaleFactor		= 0;
   CGFloat scaledWidth		= targetWidth;
   CGFloat scaledHeight		= targetHeight;
   CGPoint thumbnailPoint	= CGPointMake(0, 0);
   
   if (CGSizeEqualToSize(imageSize, targetSize) == NO) 
   {
        CGFloat widthFactor		= targetWidth  / width;
        CGFloat heightFactor	= targetHeight / height;
      
        if (widthFactor > heightFactor) 
		{
			scaleFactor = widthFactor; // scale to fit height
        }
		else
		{
			scaleFactor = heightFactor; // scale to fit width
		}
		
		scaleFactor *= 1.1;
		
        scaledWidth  = width  * scaleFactor;
        scaledHeight = height * scaleFactor;

        // Center the image
        if (widthFactor > heightFactor)
		{
			thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
		}
        else if (widthFactor < heightFactor)
		{
			thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
		}
   }
   
   UIGraphicsBeginImageContext(targetSize); // this will crop
   
   CGRect thumbnailRect			= CGRectZero;
   thumbnailRect.origin			= thumbnailPoint;
   thumbnailRect.size.width		= scaledWidth;
   thumbnailRect.size.height	= scaledHeight;
   
   [sourceImage drawInRect: thumbnailRect];
   
   newImage = UIGraphicsGetImageFromCurrentImageContext();
   if(newImage == nil) 
   {
        NSLog(@"could not scale image");
   }
   
   // Pop the context to get back to the default
   UIGraphicsEndImageContext();
   return newImage;
}

@end