#import <Foundation/Foundation.h>
#import "DataStore.h"

@interface UpdateManager : NSObject
{
	DataStore		*dataStore;
	BOOL			updating;
}

@property (readonly) BOOL updating;

- (void) update;
- (void) resendNotifications;
+ (UpdateManager *) sharedUpdateManager;

@end