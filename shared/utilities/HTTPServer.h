#import <Cocoa/Cocoa.h>

@interface HTTPServer : NSObject
{
	NSString			*content;
	
	NSSocketPort		*socketPort;
	NSFileHandle		*socketHandle;
	NSTimer				*stopTimer;
}

- (NSURL *) serveContent: (NSString *) content;

- (void) start;
- (void) stop;
- (int) port;
- (NSString *) ipAddressForFileHandle: (NSFileHandle *) fileHandle;

+ (HTTPServer *) sharedHTTPServer;

@end