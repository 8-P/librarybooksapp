#import <Foundation/Foundation.h>
#import "URL.h"
#import "ImageBridge.h"

@interface GoogleBookSearch : NSObject
{
}

+ (GoogleBookSearch *) googleBookSearch;
- (URL *) searchURLForTitle: (NSString *) title author: (NSString *) author isbn: (NSString *) isbn;
- (ImageBridge *) imageForURL: (URL *) url;
- (URL *) infoLinkForURL: (URL *) url;
- (NSString *) normaliseAuthor: (NSString *) author;
- (NSString *) normaliseTitle: (NSString *) title;

@end