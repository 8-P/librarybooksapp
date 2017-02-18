#import "HTMLTidySettings.h"
#import "RegexKitLite.h"

@implementation HTMLTidySettings

@dynamic noTidyURLs;
@synthesize prefilterBlock;

- (id) init
{
	self = [super init];
	[self reset];
	return self;
}

- (void) reset
{
	self.noTidyURLs = nil;
	self.prefilterBlock = nil;
}

- (BOOL) isTidyAllowedForURL: (NSURL *) url
{
	if (self.noTidyURLs)
	{
		NSString *urlString = [url absoluteString];
		for (NSString *regex in self.noTidyURLs)
		{
			if ([urlString isMatchedByRegex: regex]) return NO;
		}
	}
	
	return YES;
}

// -----------------------------------------------------------------------------
//
// Set the URLs that HTMLTidy should *not* run on.  The input can either be
// NSArray or NSMutableArray.
//
// -----------------------------------------------------------------------------
- (void) setNoTidyURLs: (id) value
{
	[noTidyURLs release];
	if ([value isKindOfClass: [NSMutableArray class]])
	{
		noTidyURLs = [value retain];
	}
	else
	{
		noTidyURLs = [value mutableCopy];
	}
}

- (NSMutableArray *) noTidyURLs
{
	if (noTidyURLs == nil)
	{
		self.noTidyURLs = [NSMutableArray array];
	}
	
	return noTidyURLs;
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static HTMLTidySettings *sharedSettings = nil;

+ (HTMLTidySettings *) sharedSettings
{
    @synchronized(self)
	{
        if (sharedSettings == nil)
		{
            sharedSettings = [[HTMLTidySettings alloc] init];
        }
    }
	
    return sharedSettings;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedSettings == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedSettings;
}

- (id) copyWithZone:(NSZone *)zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (NSUInteger) retainCount
{
	// Denotes an object that cannot be released
    return NSUIntegerMax;
}

- (oneway void) release
{
    // Do nothing
}

- (id) autorelease
{
    return self;
}

@end
