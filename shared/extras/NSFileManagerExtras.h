#import <Foundation/Foundation.h>

@interface NSFileManager (NSFileManagerExtras)

- (BOOL) createDirectoryAtPath: (NSString *) path;
- (NSString *) desktopDirectory;
- (NSURL *) desktopDirectoryURL;
- (NSString *) applicationSupportDirectory;
- (NSString *) temporaryDirectory;
- (BOOL) gzipFileAtPath: (NSString *) inputFile toPath: (NSString *) outputFile;

@end