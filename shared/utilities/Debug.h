#import <Foundation/Foundation.h>

@interface Debug : NSObject
{
}

+ (void) clearLog;
+ (void) log: (NSString *) format, ...;
+ (void) logError: (NSString *) format, ...;
+ (void) logDetails: (NSString *) details withSummary: (NSString *) summary, ...;
+ (void) space;
+ (void) divider;

+ (void) setSecretStrings: (NSArray *) secrets;
+ (NSString *) stringWithMaskedSecrets: (NSString *) string;

+ (void) logLastCrashReport;

+ (NSString *) html;
+ (void) saveLogToDisk;
+ (NSString *) logFilePath;
+ (NSString *) gzippedLogFilePath;

@end