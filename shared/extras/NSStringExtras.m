#import "NSStringExtras.h"
#import "NSMutableStringExtras.h"
#import "NSScannerExtras.h"
#import "RegexKitLite.h"
#import <CommonCrypto/CommonDigest.h>

// Macros ----------------------------------------------------------------------

#define UTF8(s) [NSString stringWithUTF8String: (s)]

// Constants -------------------------------------------------------------------

static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation NSString (NSStringExtras)

// -----------------------------------------------------------------------------
//
// This version of stringByAddingPercentEscapesUsingEncoding that handles the
// reserved characters.
//
// See <http://www.blooberry.com/indexdot/html/topics/urlencoding.htm> for a list
// of characters to encode.
//
// -----------------------------------------------------------------------------
- (NSString *) URLEncode
{
	NSString *encodedString = (NSString *) CFURLCreateStringByAddingPercentEscapes(
		NULL, (CFStringRef) self, NULL, CFSTR("$&+,/:;=?@ <>#%{}|\\^~[]`"),
		kCFStringEncodingUTF8);
		
	return [encodedString autorelease];
}

// -----------------------------------------------------------------------------
//
// Similar to URLEncode but alphanumeric characters are also encoded to
// obfuscate the string.
//
// -----------------------------------------------------------------------------
- (NSString *) URLObfuscate
{
	NSString *encodedString = (NSString *) CFURLCreateStringByAddingPercentEscapes(
		NULL, (CFStringRef) self, NULL,
		CFSTR("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789$&+,/:;=?@ <>#%{}|\\^~[]`"),
		kCFStringEncodingUTF8);
		
	return [encodedString autorelease];
}

// -----------------------------------------------------------------------------
//
// See if the string contains this sub string.
//
// -----------------------------------------------------------------------------
- (BOOL) hasSubString: (NSString *) string
{
	NSRange searchRange = [self rangeOfString: string];
	return searchRange.location != NSNotFound;
}

- (BOOL) hasSubStringWithFormat: (NSString *) format, ...
{
	// Build up the string
	va_list arguments;
	va_start(arguments, format);
	NSString *string = [[NSString alloc] initWithFormat: format arguments: arguments];
	va_end(arguments);
	
	BOOL result = [self hasSubString: string];
	[string release];
	
	return result;
}

- (BOOL) hasCaseInsensitiveSubString: (NSString *) string
{
	NSRange searchRange = [self rangeOfString: string options: NSCaseInsensitiveSearch];
	return searchRange.location != NSNotFound;
}

// -----------------------------------------------------------------------------
//
// Count the occurances of the specified substring.
//
// -----------------------------------------------------------------------------
- (int) countOccurancesOfCaseInsensitiveSubString: (NSString *) string
{
	int count			= 0;
	NSScanner *scanner	= [NSScanner scannerWithString: self];
	
	while ([scanner scanPassString: string])
	{
		count++;
	}
	
	return count;
}

// -----------------------------------------------------------------------------
//
// Delete occurances of a particular string.
//
// -----------------------------------------------------------------------------
- (NSString *) stringByDeletingOccurrencesOfString: (NSString *) string
{
	if ([self hasSubString: string] == YES)
	{
		NSMutableString *mutableString = [NSMutableString stringWithString: self];
		[mutableString replaceOccurrencesOfString: string withString: @""
			options: 0 range: NSMakeRange(0, [mutableString length])];
			
		return mutableString;
	}
	else
	{
		return self;
	}
}

// -----------------------------------------------------------------------------
//
// Remove HTML tags to turn a fragment of HTML into a piece of plain text.
//		* All characters between < and > are removed.
//		* Escape sequences such as &amp; are converted into their character
//		  equivalents.
//		* There is special handling for <select/> elements.
//
// -----------------------------------------------------------------------------
- (NSString *) stringWithoutHTML
{
	NSMutableString *string = [[self mutableCopy] autorelease];
	
	// Handle <selects/> as we don't want to show all options.  Just
	// the default one
	if ([string hasSubString: @"<select"])
	{
		NSScanner *scanner	= [NSScanner scannerWithString: string];
		
		HTMLElement *optionElement;
		while ([scanner scanNextElementWithName: @"select" intoElement: &optionElement])
		{
			HTMLElement *selectElement;
			if ([optionElement.scanner scanNextElementWithName: @"option" attributeKey: @"selected" attributeValue: @"selected" intoElement: &selectElement])
			{
				[string replaceOccurrencesOfString: optionElement.value withString: selectElement.value];
			}
		}
	}
	
	// Strip out tags
	NSRange startRange;
	while ((startRange = [string rangeOfString: @"<"]).location != NSNotFound)
	{
		NSRange endRange = [string rangeOfString: @">"];
		if (endRange.location == NSNotFound)
		{
			// Default to the end of the string
			endRange = NSMakeRange([string length], 0);
		}
		else if (endRange.location < startRange.location)
		{
			// We have a ">" before a "<" so we need to delete everything up to the ">"
			startRange = NSMakeRange(0, 0);
		}
		
		NSRange tagRange = NSMakeRange(startRange.location,
			endRange.location + endRange.length - startRange.location);
		[string deleteCharactersInRange: tagRange];
	}
	
	// Replace line break and tabs white spaces
	[string replaceOccurrencesOfString: @"\n" withString: @" "];
	[string replaceOccurrencesOfString: @"\t" withString: @" "];
	
	// Collapse all extra whitespace characters down to a single one
	NSMutableArray *words = [NSMutableArray arrayWithArray: [string componentsSeparatedByString: @" "]];
	[words removeObject: @""];
	string = [[[words componentsJoinedByString: @" "] mutableCopy] autorelease];
	
	// Translate entities
	[string replaceOccurrencesOfString: @"&nbsp;" withString: @" "];
	[string replaceOccurrencesOfString: @"&quot;" withString: @"\""];
	[string replaceOccurrencesOfString: @"&gt;" withString: @">"];
	[string replaceOccurrencesOfString: @"&lt;" withString: @"<"];
	[string replaceOccurrencesOfString: @"&amp;" withString: @"&"];
	
	// Translate number encoded enties (CARLweb uses these for characters
	// other than A-Z).
	//
	// Warning: code is inefficient for large strings
	// Note:    does not handle hex encoded values
	NSArray *captures = [string arrayOfCaptureComponentsMatchedByRegex: @"&#([0-9]+);"];
	for (NSArray *capture in captures)
	{
		if ([capture count] > 1)
		{
			NSString *from				= [capture objectAtIndex: 0];
			NSUInteger characterCode	= [[capture objectAtIndex: 1] integerValue];
			NSString *to				= [NSString stringWithFormat: @"%C", (unsigned short) characterCode];
			
			[string replaceOccurrencesOfString: from withString: to];
		}
	}
	
	return string;
}

// -----------------------------------------------------------------------------
//
// Encode the string using HTML entites.
//
// E.g. & -> &amp;
//
// -----------------------------------------------------------------------------
- (NSString *) stringToHTML
{
	NSMutableString *string = [[self mutableCopy] autorelease];
	
	[string replaceOccurrencesOfString: @"&" withString: @"&amp;"];
	[string replaceOccurrencesOfString: @"<" withString: @"&lt;"];
	[string replaceOccurrencesOfString: @">" withString: @"&gt;"];
	
	return string;
}

+ (NSString *) stringWithData: (NSData *) data encoding: (NSStringEncoding) encoding
{
	return [[[NSString alloc] initWithData: data encoding: encoding] autorelease];
}

// -----------------------------------------------------------------------------
//
// Example: converts from "utf-8" to NSUTF8StringEncoding.
//
// -----------------------------------------------------------------------------
+ (NSStringEncoding) stringEncodingForIANACharSetName: (NSString *) name
{
	if (name == nil)
	{
		// Default to the ISO Latin 1 encoding
		return NSISOLatin1StringEncoding;
	}
	else
	{
		return CFStringConvertEncodingToNSStringEncoding(
			CFStringConvertIANACharSetNameToEncoding((CFStringRef) name));
	}
}

- (NSString *) stringWithBase64Encoding
{
	if ([self length] == 0)
		return @"";

    char *characters = malloc((([self length] + 2) / 3) * 4);
	if (characters == NULL)
		return nil;
	NSUInteger length = 0;
	
	NSUInteger i = 0;
	while (i < [self length])
	{
		char buffer[3] = {0,0,0};
		short bufferLength = 0;
		while (bufferLength < 3 && i < [self length])
		{
			buffer[bufferLength] = (char) [self characterAtIndex: i];
			i++;
			bufferLength++;
		}
		
		//  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
		characters[length++] = encodingTable[(buffer[0] & 0xFC) >> 2];
		characters[length++] = encodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];
		if (bufferLength > 1)
			characters[length++] = encodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
		else characters[length++] = '=';
		if (bufferLength > 2)
			characters[length++] = encodingTable[buffer[2] & 0x3F];
		else characters[length++] = '=';
	}
	
	return [[[NSString alloc] initWithBytesNoCopy:characters length:length encoding:NSASCIIStringEncoding freeWhenDone:YES] autorelease];
}

- (NSString *) stringByTrimmingWhitespace
{
	return [self stringByTrimmingCharactersInSet:
		[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL) isNumber
{
	NSMutableCharacterSet *set = [NSMutableCharacterSet decimalDigitCharacterSet];
	[set addCharactersInString: @"+-."];
	[set invert];
	
	return [self rangeOfCharacterFromSet: set].location == NSNotFound;
}

// -----------------------------------------------------------------------------
//
// Strip out HTML comments
//
// -----------------------------------------------------------------------------
- (NSString *) stringWithoutHTMLComments
{
	NSMutableString *string = [NSMutableString stringWithString: self];

	NSRange startRange;	
	while ((startRange = [string rangeOfString: @"<!--" ]).location != NSNotFound)
	{
		NSRange endRange = [string rangeOfString: @"-->" options: 0
			range: NSMakeRange(startRange.location, [string length] - startRange.location)];
		if (endRange.location == NSNotFound)
		{
			// Default to the end of the string
			endRange = NSMakeRange([string length], 0);
		}
		
		NSRange commentRange = NSMakeRange(startRange.location,
			endRange.location + endRange.length - startRange.location);
		[string deleteCharactersInRange: commentRange];
	}
	
	return string;
}

// -----------------------------------------------------------------------------
//
// Strip out HTML <script></script> elements.
//
// -----------------------------------------------------------------------------
- (NSString *) stringWithoutHTMLScripts
{
	NSMutableString *string = [NSMutableString stringWithString: self];

	NSRange startRange;	
	while ((startRange = [string rangeOfString: @"<script" ]).location != NSNotFound)
	{
		NSRange endRange = [string rangeOfString: @"</script>" options: 0
			range: NSMakeRange(startRange.location, [string length] - startRange.location)];
		if (endRange.location == NSNotFound)
		{
			// Default to the end of the string
			endRange = NSMakeRange([string length], 0);
		}
		
		NSRange commentRange = NSMakeRange(startRange.location,
			endRange.location + endRange.length - startRange.location);
		[string deleteCharactersInRange: commentRange];
	}
	
	return string;
}

- (BOOL) hasWord: (NSString *) string
{
	return [self isMatchedByRegex: [NSString stringWithFormat: @"\\b%@\\b", string]];
}

// -----------------------------------------------------------------------------
//
// Return YES if one of the words is in the string.
//
// -----------------------------------------------------------------------------
- (BOOL) hasWords: (NSArray *) words
{
	for (NSString *word in words)
	{
		if ([self hasWord: word]) return YES;
	}
	
	return NO;
}

- (NSArray *) words
{
	return [self componentsSeparatedByCharactersInSet:
		[NSCharacterSet characterSetWithCharactersInString: @" -.,;:/\t\r\n"]];
}

- (NSString *) stringUptoLast: (NSString *) string
{
	NSRange range = [self rangeOfString: string options: NSBackwardsSearch | NSCaseInsensitiveSearch];
	if (range.location == NSNotFound) return self;
	
	return [self substringToIndex: range.location];
}

- (NSString *) stringUptoFirst: (NSString *) string
{
	NSRange range = [self rangeOfString: string options: NSCaseInsensitiveSearch];
	if (range.location == NSNotFound) return self;
	
	return [self substringToIndex: range.location];
}

- (NSString *) stringWithoutQuotes
{
	NSString *string = [self stringByDeletingOccurrencesOfRegex: @"^\""];
	string = [string stringByDeletingOccurrencesOfRegex: @"\"$"];
	
	return string;
}

- (NSString *) nilIfEmpty
{
	if ([self length] == 0)
	{
		return nil;
	}
	
	return self;
}

// -----------------------------------------------------------------------------
//
//		* stringByDeletingLastPathComponent will changes "http://" -> "http:/",
//		  The regex puts the missing slash back in.
//
// -----------------------------------------------------------------------------
- (NSString *) urlStringByDeletingLastPathComponent
{
	NSString *string = [self stringByDeletingLastPathComponent];
	string = [string stringByReplacingOccurrencesOfRegex: @"^(https?:/)([^/])" withString: @"$1/$2"];
	
	return string;
}

// -----------------------------------------------------------------------------
//
// This method is useful for splitting combined author and title strings.
//
// -----------------------------------------------------------------------------
- (BOOL) splitStringOn: (NSString *) divider  intoLeft: (NSString **) left intoRight: (NSString **) right
	options: (unsigned) mask
{
	NSRange range = [self rangeOfString: divider options: mask];
	
	if (range.location == NSNotFound)
	{
		// If we can't split the string just set the left string to the whole
		// strong.  Note that we don't overwrite the existing value of the right
		// string
		*left = [self stringByTrimmingWhitespace];
		
		return NO;
	}
		
	*left = [self substringToIndex: range.location];
	if (*left == nil) return NO;
	*left = [*left stringByTrimmingWhitespace];
	
	*right = [self substringFromIndex: range.location + range.length];
	if (*right == nil) return NO;
	*right = [*right stringByTrimmingWhitespace];
	
	return YES;
}

- (BOOL) splitStringOnFirst: (NSString *) divider intoLeft: (NSString **) left intoRight: (NSString **) right
{
	return [self splitStringOn: divider intoLeft: left intoRight: right options: 0];
}

- (BOOL) splitStringOnLast: (NSString *) divider intoLeft: (NSString **) left intoRight: (NSString **) right
{
	return [self splitStringOn: divider intoLeft: left intoRight: right options: NSBackwardsSearch];
}

- (NSString *) stringByDeletingOccurrencesOfRegex: (NSString *) regex
{
	return [self stringByReplacingOccurrencesOfRegex: regex withString: @""];
}

// -----------------------------------------------------------------------------
//
// Calculate MD5 hash.
//
// Copied from:
//		* http://stackoverflow.com/questions/652300/using-md5-hash-on-a-string-in-cocoa
//		* http://amcmillan.livejournal.com/155200.html
//
// -----------------------------------------------------------------------------
- (NSString *) md5AsLowerCaseHex
{
	const char *cString = [self UTF8String];
	
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(cString, strlen(cString), result);
	
	return [NSString stringWithFormat:
		@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
		result[ 0], result[ 1], result[ 2], result[ 3], 
		result[ 4], result[ 5], result[ 6], result[ 7],
		result[ 8], result[ 9], result[10], result[11],
		result[12], result[13], result[14], result[15]
	];
}

- (NSString *) stringWithQuotes
{
	return [NSString stringWithFormat: @"\"%@\"", self];
}

@end