#import <Foundation/Foundation.h>

@interface Settings : NSObject
{
	NSUserDefaults	*defaults;
	NSDictionary	*overdueAlertProperties;
}

@property(retain)	NSDictionary	*overdueAlertProperties;
@property(readonly) NSString		*overdueAlertTitle;
@property(readonly) NSNumber		*overdueAlertValue;

@property			BOOL			bookCovers;

@property			BOOL			autoUpdate;
@property(readonly)	NSTimeInterval	secondsSinceLastAutoUpdate;

@property			BOOL			overdueNotification;

@property			BOOL			appBadge;

- (void) initOverdueAlert;
- (void) initBookCovers;
- (void) initAutoUpdate;
- (void) setLastAutoUpdateToNow;
- (void) initOverdueNotification;
- (void) initAppBadge;
+ (Settings *) sharedSettings;

@end