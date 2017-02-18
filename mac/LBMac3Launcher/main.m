#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	@autoreleasepool
	{
		NSString *appPath = [[NSBundle mainBundle] bundlePath];
		appPath = [appPath stringByDeletingLastPathComponent];
		appPath = [appPath stringByDeletingLastPathComponent];
		appPath = [appPath stringByDeletingLastPathComponent];
		appPath = [appPath stringByDeletingLastPathComponent];

		if ([[NSWorkspace sharedWorkspace] launchApplication: appPath] == NO)
		{
			NSLog(@"Failed to launch Library Books at [%@]", appPath);
		}
	}
	
	return 0;
}