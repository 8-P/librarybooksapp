#import <Foundation/Foundation.h>

@interface HTMLTidySettings : NSObject
{
	NSMutableArray *noTidyURLs;
	NSString *(^prefilterBlock)(NSString *);
}

@property(retain) NSMutableArray *noTidyURLs;
@property(copy) NSString *(^prefilterBlock)(NSString *);

- (void) reset;
- (BOOL) isTidyAllowedForURL: (NSURL *) url;
+ (HTMLTidySettings *) sharedSettings;

@end