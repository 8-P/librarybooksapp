#import "Debug.h"
#import "SharedExtras.h"
#import "DataStore.h"
#import "NSFileManagerExtras.h"

@implementation Debug

// Globals ---------------------------------------------------------------------

static NSMutableString	*logString		= nil;
static NSMutableArray	*secretStrings	= nil;
static int nextId;

// =============================================================================
#pragma mark -
#pragma mark Updating debug

+ (void) clearLog
{
	[logString release];
	logString = [[NSMutableString string] retain];
}

+ (void) log: (NSString *) format, ...
{
	if (logString == nil) logString = [[NSMutableString string] retain];
	
	va_list arguments, arguments_copy;
	va_start(arguments, format);
	va_copy(arguments_copy, arguments);
	
	// Send to NSLog too.  This makes is easier to do debugging as it ends up in
	// the console log
	if ([NSUserDefaults.standardUserDefaults boolForKey: @"DebugNSLog"]) NSLogv(format, arguments);
	
	// Write to the log
	[logString appendString: @"<div class='m'>"];
	NSString *string = [[NSString alloc] initWithFormat: format arguments: arguments_copy];
	[logString appendString: [[Debug stringWithMaskedSecrets: string] stringToHTML]];
	[logString appendString: @"</div>\n"];
	[string release];
	
	va_end(arguments);
	va_end(arguments_copy);
}

+ (void) logError: (NSString *) format, ...
{
	if (logString == nil) logString = [[NSMutableString string] retain];
	
	va_list arguments, arguments_copy;
	va_start(arguments, format);
	va_copy(arguments_copy, arguments);
	
	// Send to NSLog too.  This makes is easier to do debugging as it ends up in
	// the console log
	if ([NSUserDefaults.standardUserDefaults boolForKey: @"DebugNSLog"]) NSLogv(format, arguments);

	// Write to the log
	[logString appendString: @"<div class='m'><span class='e'>"];
	NSString *string = [[NSString alloc] initWithFormat: format arguments: arguments_copy];
	[logString appendString: [[Debug stringWithMaskedSecrets: string] stringToHTML]];
	[logString appendString: @"</span></div>\n"];
	[string release];
	
	va_end(arguments);
	va_end(arguments_copy);
}

+ (void) logDetails: (NSString *) details withSummary: (NSString *) summaryFormat, ...
{
	if (logString == nil) logString = [[NSMutableString string] retain];
	if (details == nil) details = @"";

	// Build up the summary string
	va_list arguments;
	va_start(arguments, summaryFormat);
	NSString *summary = [[NSString alloc] initWithFormat: summaryFormat arguments: arguments];
	va_end(arguments);

	// Add to the log
	[logString appendString: @"<div class='d'>"];
	if ([details length] > 0)
	{
		if ([details hasCaseInsensitiveSubString: @"<html"])
		{
			// Display "Raw HTML | Web Page"
			[logString appendFormat: @"%@ - <a href='javascript:displayRawHTML(\"%d\")'>Raw HTML</a> | <a href='javascript:displayWebPage(\"%d\")'>Web Page</a>\n",
				summary, nextId, nextId];
		}
		else
		{
			// Display "Data"
			[logString appendFormat: @"%@ - <a href='javascript:displayRawHTML(\"%d\")'>Data</a>\n", summary, nextId];
		}
	}
	else
	{
		[logString appendFormat: @"%@ -\n", summary];
	}
	[logString appendFormat: @"(%ld bytes)</div>\n", (long) [details length]];
	[logString appendFormat: @"<div id='%d' class='h'>\n", nextId];
	[logString appendString: [[Debug stringWithMaskedSecrets: details] stringWithBase64Encoding]];
	[logString appendString: @"</div>\n"];
	
	[summary release];
	
	nextId++;
}

+ (void) space
{
	[logString appendString: @"<div class='s'></div>\n"];
}

+ (void) divider
{
	[logString appendString: @"<hr/>\n"];
}

// =============================================================================
#pragma mark -
#pragma mark Secret string handling

// -----------------------------------------------------------------------------
//
// The debug log can contain secret information like pin numbers so we need to
// mask them.
// 
// -----------------------------------------------------------------------------
+ (void) setSecretStrings: (NSArray *) secrets
{
	[secretStrings release];
	secretStrings = [[NSMutableArray arrayWithCapacity: [secrets count]] retain];
	
	// Only accept secret strings longer than 1 character
	for (NSString *secret in secrets)
	{
		if (secret && [secret length] > 1)
		{
			[secretStrings addObject: secret];
		}
	}
}

+ (NSString *) stringWithMaskedSecrets: (NSString *) string
{
	if (secretStrings == nil) return string;

	NSMutableString *maskedString = [[string mutableCopy] autorelease];
	for (NSString *secret in secretStrings)
	{
		NSString *mask = [@"" stringByPaddingToLength: [secret length] withString: @"*" startingAtIndex: 0];
		[maskedString replaceOccurrencesOfString: secret withString: mask];
	}
	
	return maskedString;
}

// =============================================================================
#pragma mark -
#pragma mark Crash logs

// -----------------------------------------------------------------------------
//
// Append the last crash report.
//
// -----------------------------------------------------------------------------
+ (void) logLastCrashReport
{
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR || APP_STORE
#else
	NSString *path				= [@"~/Library/Logs/CrashReporter/" stringByExpandingTildeInPath];
	NSDirectoryEnumerator *e	= [[NSFileManager defaultManager] enumeratorAtPath: path];
	NSString *appName			= [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleName"];
	NSMutableArray *array		= [NSMutableArray array];
	
	NSString *file;
	while (file = [e nextObject])
	{
		if ([file hasPrefix: appName])
		{
			[array addObject: [[NSString stringWithFormat:@"~/Library/Logs/CrashReporter/%@", file] stringByExpandingTildeInPath]];
		}
	}
	
	NSArray *sortedArray = [array sortedArrayUsingSelector: @selector(compare:)];
	if ([sortedArray count] > 0)
	{
		NSString *file = [sortedArray lastObject];
		NSString *crashReport = [NSString stringWithContentsOfFile: file encoding: NSUTF8StringEncoding error: nil];
		
		[Debug divider];
		[Debug logDetails: crashReport withSummary: @"Crash report [%@]", file];
	}
#endif
}

// =============================================================================
#pragma mark -
#pragma mark Saving and retrieving

+ (NSString *) html
{
	if (logString == nil) return nil;
	
	// Add in the HTML header and footers
	NSString *filePath		= [[NSBundle mainBundle] pathForResource: @"DebugStrings" ofType: @"plist"];
	NSDictionary *strings	= [NSDictionary dictionaryWithContentsOfFile: filePath];

	NSString *header = [strings objectForKey: @"HtmlHeader"];
	NSString *footer = [strings objectForKey: @"HtmlFooter"];

	NSMutableString *html = [NSMutableString string];
	if (header) [html appendString: header];
	[Debug logLastCrashReport];
	[html appendString: logString];
	if (footer) [html appendString: footer];

	return html;
}

+ (void) saveLogToDisk
{
	NSString *html = [self html];
	if (html)
	{
		[html writeToFile: [self logFilePath] atomically: YES encoding: NSUTF8StringEncoding error: nil];
	}
}

+ (NSString *) logFilePath
{
	return [[[NSFileManager defaultManager] applicationSupportDirectory] stringByAppendingPathComponent: @"Debug.html"];
}

// -----------------------------------------------------------------------------
//
// Return the path to the gzipped log file.  Log files can get very big so it is
// a good idea to gzip the file.
//
// -----------------------------------------------------------------------------
+ (NSString *) gzippedLogFilePath
{
	NSFileManager *fileManager	= [NSFileManager defaultManager];
	NSString *directory			= [fileManager applicationSupportDirectory];
	NSString *from				= [directory stringByAppendingPathComponent: @"Debug.html"];
	NSString *to				= [directory stringByAppendingPathComponent: @"Debug.html.gz"];
	
	[fileManager gzipFileAtPath: from toPath: to];
	
	return to;
}

@end
