// =============================================================================
//
// How to: http://blog.mcohen.me/2012/01/12/login-items-in-the-sandbox/
//
// To check:
//
//		launchctl list | grep -i myki
//
// =============================================================================

#import "LoginItems.h"
#import <ServiceManagement/ServiceManagement.h>

@implementation LoginItems

#if APP_STORE
static NSString *bundleID = @"au.id.haroldchu.mac.librarybookslauncher";
#else
//static NSString *bundleID = @"au.id.haroldchu.librarybookslauncher";
#endif

+ (BOOL) enableLoginItem: (BOOL) enabled
{
#if APP_STORE
    Boolean success	= SMLoginItemSetEnabled((CFStringRef) bundleID, enabled);
	if (!success)
	{
		NSLog(@"Failed to enabled login");
		return NO;
	}
	
	return YES;
#else
	if (enabled)	[LoginItems addLoginItem];
	else			[LoginItems removeLoginItem];
	
	return YES;
#endif
}

+ (BOOL) isLoginItemEnabled
{
#if APP_STORE
	BOOL enabled = NO;

	CFArrayRef dictionaries = SMCopyAllJobDictionaries(kSMDomainUserLaunchd);
	if (dictionaries)
	{
		long count = CFArrayGetCount(dictionaries);
		for (int i = 0; i < count; i++)
		{
			NSDictionary *job = (NSDictionary *) CFArrayGetValueAtIndex(dictionaries, i);
			if ([bundleID isEqualToString: [job objectForKey: @"Label"]])
			{
				enabled = [[job objectForKey: @"OnDemand"] boolValue];
				break;
			}
		}
		
		CFRelease(dictionaries);
	}
	
    return enabled;
#else
	return [LoginItems isLoginItem];
#endif
}

+ (void) addLoginItem
{
	NSString *appPath = [[NSBundle mainBundle] bundlePath];

	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems)
	{
		CFURLRef url = (CFURLRef) [NSURL fileURLWithPath: appPath]; 
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(
			loginItems, kLSSharedFileListItemLast, NULL, NULL, url, NULL, NULL);
		if (item) CFRelease(item);
		
		CFRelease(loginItems);
	}
}

+ (void) removeLoginItem
{
	NSString *appPath = [[NSBundle mainBundle] bundlePath];

	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems)
	{
		UInt32 seed = 0;
		NSArray *loginItemsArray = (NSArray *) LSSharedFileListCopySnapshot(loginItems, &seed);
		[loginItemsArray autorelease];
		
		for (id itemObject in loginItemsArray)
		{
			LSSharedFileListItemRef item = (LSSharedFileListItemRef) itemObject;
			
			CFURLRef url = NULL;
			OSStatus error = LSSharedFileListItemResolve(item, 0, &url, NULL);
			if (error == noErr)
			{
				NSString *urlPath = [(NSURL *) url path];
				CFRelease(url);
				
				if ([urlPath isEqualToString: appPath])
				{
					LSSharedFileListItemRemove(loginItems, item);
					break;
				}
			}
		}
	}
}

+ (BOOL) isLoginItem
{
	NSString *appPath = [[NSBundle mainBundle] bundlePath];
	
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems)
	{
		UInt32 seed = 0;
		NSArray *loginItemsArray = (NSArray *) LSSharedFileListCopySnapshot(loginItems, &seed);
		[loginItemsArray autorelease];
		
		for (id itemObject in loginItemsArray)
		{
			LSSharedFileListItemRef item = (LSSharedFileListItemRef) itemObject;
		
			CFURLRef url = NULL;
			OSStatus error = LSSharedFileListItemResolve(item, 0, &url, NULL);
			if (error == noErr)
			{
				NSString *urlPath = [(NSURL *) url path];
				CFRelease(url);
				
				if ([urlPath isEqualToString: appPath])
				{
					return YES;
				}
			}
		}
	}
	
	return NO;
}

@end