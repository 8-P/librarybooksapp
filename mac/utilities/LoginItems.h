#import <Foundation/Foundation.h>

@interface LoginItems : NSObject
{
}

+ (BOOL) enableLoginItem: (BOOL) enabled;
+ (BOOL) isLoginItemEnabled;

+ (void) addLoginItem;
+ (void) removeLoginItem;
+ (BOOL) isLoginItem;

@end