#import <Cocoa/Cocoa.h>

@interface LBMac3_AppDelegate : NSObject
{
    NSWindow *window;
	NSManagedObject *managedObjectContext;
}

@property (nonatomic, retain) IBOutlet NSWindow *window;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@end
