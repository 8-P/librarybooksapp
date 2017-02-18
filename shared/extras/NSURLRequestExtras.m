#import "NSURLRequestExtras.h"

// -----------------------------------------------------------------------------
// Override default behaviour and accept bad certificates.
//
// See <http://www.cocoabuilder.com/archive/message/cocoa/2005/1/20/126166>
//
// -----------------------------------------------------------------------------
@implementation NSURLRequest (NSURLRequestExtras)

+ (BOOL) allowsAnyHTTPSCertificateForHost: (NSString *)host
{
	return YES;
}

@end