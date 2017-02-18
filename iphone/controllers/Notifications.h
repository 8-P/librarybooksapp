#import <Foundation/Foundation.h>

@interface Notifications : NSObject
{
}

+ (Notifications *) notifications;
- (void) update;
- (Class) localNotificationClass;

@end