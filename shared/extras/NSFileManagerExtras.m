#import "NSFileManagerExtras.h"
#include "zlib.h"

#define GZIP_CHUNK 16384

@implementation NSFileManager (NSFileManagerExtras)

- (BOOL) createDirectoryAtPath: (NSString *) path
{
	if ([self fileExistsAtPath: path isDirectory: NULL] == NO)
	{
		NSError *error = nil;
		if ([self createDirectoryAtPath: path withIntermediateDirectories: YES attributes: nil error: &error] == NO)
		{
			NSLog(@"Error creating application support directory at [%@]: %@", path, error);
            return NO;
		}
    }
	
	return YES;
}

- (NSString *) desktopDirectory
{
	return [NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSURL *) desktopDirectoryURL
{
	return [NSURL fileURLWithPath: [self desktopDirectory]];
}

// -----------------------------------------------------------------------------
//
// Returns the path to the application's documents directory.
//
// -----------------------------------------------------------------------------
- (NSString *) applicationSupportDirectory
{	
    NSString *basePath	= [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *fullPath	= [basePath stringByAppendingPathComponent: @"Library Books"];
	
	[self createDirectoryAtPath: fullPath];
	
	return fullPath;
}

- (NSString *) temporaryDirectory
{	
    NSString *basePath	= NSTemporaryDirectory();
    NSString *fullPath	= [basePath stringByAppendingPathComponent: @"Library Books"];
	
	[self createDirectoryAtPath: fullPath];
	
	return fullPath;
}

// -----------------------------------------------------------------------------
//
// Based on example from:
// http://codeguru.earthweb.com/cpp/cpp/algorithms/compression/print.php/c11735
//
// -----------------------------------------------------------------------------
- (BOOL) gzipFileAtPath: (NSString *) inputPath toPath: (NSString *) outputPath
{
	FILE *inFile	= fopen([inputPath cStringUsingEncoding: NSASCIIStringEncoding], "rb");
	gzFile outFile	= gzopen([outputPath cStringUsingEncoding: NSASCIIStringEncoding], "wb");
	
	if (!inFile || !outFile) return NO;
	
	char buffer[GZIP_CHUNK];
	int length;
	while ((length = fread(buffer, 1, sizeof(buffer), inFile)) > 0)
	{
		gzwrite(outFile, buffer, length);
	}
	
	fclose(inFile);
	gzclose(outFile);

	return YES;
}

@end
