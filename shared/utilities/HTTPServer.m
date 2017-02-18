#import "HTTPServer.h"
#import <sys/socket.h>
#import <netinet/in.h>
#include <arpa/inet.h>
#import "Debug.h"

@implementation HTTPServer

#define TIMEOUT 60

// Public functions ------------------------------------------------------------

- (NSString *) serveContent: (NSString *) newContent;
{
	[content release];
	content = [newContent retain];
	
	[self start];
	
	// Stop the server after 60 seconds
	[stopTimer invalidate];
	[stopTimer release];
	stopTimer = [[NSTimer scheduledTimerWithTimeInterval: TIMEOUT target: self
			selector: @selector(stop) userInfo: nil repeats: NO] retain];
	
	return [NSURL URLWithString: [NSString stringWithFormat: @"http://127.0.0.1:%d", [self port]]];
}

- (int) port
{
	struct sockaddr_in addr = *(struct sockaddr_in *) [[socketPort address] bytes];
	return ntohs(addr.sin_port);
}

- (void) start
{
	if (socketHandle) return;

	// Bind to the loopback interface only (127.0.0.1)
	struct sockaddr_in address;
	memset(&address, 0, sizeof(address));
	address.sin_port = htons(0);
	address.sin_family = AF_INET;
	address.sin_addr.s_addr = inet_addr("127.0.0.1");

	NSData *addressData = [NSData dataWithBytes: &address length: sizeof(address)];

//	socketPort		= [[NSSocketPort alloc] initWithTCPPort: 0];
	socketPort		= [[NSSocketPort alloc] initWithProtocolFamily: PF_INET socketType: SOCK_STREAM protocol: 0 address: addressData];
	socketHandle	= [[NSFileHandle alloc] initWithFileDescriptor: [socketPort socket] closeOnDealloc: YES];
	
	// Ignore SIGPIPE when the other end disconnects during a transfer
	signal(SIGPIPE, SIG_IGN);
	
	// Set up async socket connections
	[[NSNotificationCenter defaultCenter] addObserver: self
		selector: @selector(handleSocketConnection:)
		name: NSFileHandleConnectionAcceptedNotification object: socketHandle];
	[socketHandle acceptConnectionInBackgroundAndNotify];
}

- (void) stop
{
	//NSLog(@"STOP");

	[[NSNotificationCenter defaultCenter] removeObserver: self
		name: NSFileHandleConnectionAcceptedNotification object: socketHandle];

	[socketHandle release];
	[socketPort release];	
	[content release];
	
	socketHandle = nil;
	socketPort = nil;
	content = nil;
}

- (void) handleSocketConnection: (NSNotification *) notification
{
	NSFileHandle *remoteFile = [[notification userInfo] 
		objectForKey: NSFileHandleNotificationFileHandleItem];

	if (remoteFile != nil)
	{
		// Wait for the request
		[remoteFile availableData];
	
		NSString *ipAddress = [self ipAddressForFileHandle: remoteFile];
	
		// Only display the calendar if it is a local connection
		if ([ipAddress isEqualToString: @"127.0.0.1"] == YES && content != nil)
		{
			NSData *contentData = [content dataUsingEncoding: NSUTF8StringEncoding];
		
			// Format the HTTP header
			NSString *header = [NSString stringWithFormat:
				@"HTTP/1.0 200 OK\n"
				@"Cache-Control: private, max-age=0\n"
				@"Content-Type: text/html\n"
				@"Content-Length: %lu\n\n",
				(unsigned long) [contentData length]
			];
			NSData *headerData = [header dataUsingEncoding: NSUTF8StringEncoding];
			
			[remoteFile writeData: headerData];
			[remoteFile writeData: contentData];
		}
		else
		{
			[Debug logError: @"HTTP server - outside access from [%@]", ipAddress];
		}
		
		[remoteFile closeFile];
	}
	else
	{
		[Debug logError: @"HTTP server - invalid HTTP request, stopping"];
		[self stop];
			
		return;
	}
	
	// Setup for the next client connection
	[socketHandle acceptConnectionInBackgroundAndNotify];
}

- (NSString *) ipAddressForFileHandle: (NSFileHandle *) fileHandle
{		
	struct sockaddr_in name;
	socklen_t nameLength = sizeof(struct sockaddr_in);
	getsockname([fileHandle fileDescriptor], (struct sockaddr *) &name, &nameLength);
	
	return [NSString stringWithCString: (char *) inet_ntoa(name.sin_addr) encoding: NSASCIIStringEncoding];
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static HTTPServer *sharedHTTPServer = nil;

+ (HTTPServer *) sharedHTTPServer
{
    @synchronized(self)
	{
        if (sharedHTTPServer == nil)
		{
            sharedHTTPServer = [[HTTPServer alloc] init];
        }
    }
	
    return sharedHTTPServer;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedHTTPServer == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedHTTPServer;
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
