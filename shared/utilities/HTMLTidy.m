// =============================================================================
//
// Wrapper function around the HTML Tidy library.
//
// =============================================================================

#import "HTMLTidy.h"
#import "Debug.h"
#import "SharedExtras.h"
#import "tidy.h"
#import "buffio.h"
#import "HTMLTidySettings.h"
#import "RegexKitLite.h"

@implementation HTMLTidy

+ (NSString *) tidy: (NSString *) input url: (URL *) url
{
	if ([[HTMLTidySettings sharedSettings] isTidyAllowedForURL: url] == NO)
	{
		[Debug log: @"Tidy - skipping non allowed URL"];
		return input;
	}
	
	if ([HTMLTidySettings sharedSettings].prefilterBlock)
	{
		input = [HTMLTidySettings sharedSettings].prefilterBlock(input);
	}

	// Don't run HTML tidy on non-html data:
	//		* Normally a HTML page will have a <html/> tag.
	//		* The newer Millenium pages are missing the <html/> tag
	//		  so we search for the DOCTYPE.
	//		* The Nashville Millennium page is missing the <html> tag but
	//		  has an ending </html> tag.
	if ([input hasCaseInsensitiveSubString: @"<html"] == NO
		&& [input hasCaseInsensitiveSubString: @"<!DOCTYPE html"] == NO
		&& [input hasCaseInsensitiveSubString: @"</html>"] == NO)
	{
		[Debug log: @"Tidy - skipping non HTML data"];
		return input;
	}

	// Extra hacks to handle very bad malformed HTML that tidy will reject
	input = [self preTidy: input];

	TidyDoc tdoc = tidyCreate();
	TidyBuffer output;
	tidyBufInit(&output);

	// Set options:
	//		* XHTML output
	//		* Indent it for easier reading
	//		* Disable wrapping as it mess up HTML parsing
	tidyOptSetBool(tdoc, TidyXhtmlOut, yes);
	tidyOptSetInt(tdoc, TidyIndentContent, TidyAutoState);
	tidySetCharEncoding(tdoc, "utf8");
	tidyOptSetInt(tdoc, TidyWrapLen, 0);
	tidyOptSetBool(tdoc, TidyHideComments, yes);
	
	TidyBuffer errbuf;
	tidyBufInit(&errbuf);
	tidySetErrorBuffer(tdoc, &errbuf);
	
	// Tidy up the HTML
	tidyParseString(tdoc, [input cStringUsingEncoding: NSUTF8StringEncoding]);
	tidyCleanAndRepair(tdoc);
	tidyRunDiagnostics(tdoc);
	tidyOptSetBool(tdoc, TidyForceOutput, yes);
	tidySaveBuffer(tdoc, &output);

	NSString *result;
	if (output.bp == NULL)
	{
		[Debug log: @"Tidy - failed to clean up HTML"];
		[Debug logDetails: [NSString stringWithCString: (char *) errbuf.bp encoding: NSUTF8StringEncoding] withSummary: @"Tidy - errors"];

		// Default to the input string
		result = input;
	}
	else
	{
		result = [NSString stringWithCString: (char *) output.bp encoding: NSUTF8StringEncoding];
		[Debug logDetails: result withSummary: @"Tidy - cleaned up HTML"];
	}
	
	tidyBufFree(&output);
	tidyBufFree(&errbuf);
	tidyRelease(tdoc);
		
	return result;
}

+ (NSString *) preTidy: (NSString *) input
{
	// Clean up for invalid HTML in TPL (Toronto Public Library) page
	input = [input stringByReplacingOccurrencesOfString: @"<bold>" withString: @"<b>"];
	
	// The Overdrive login pages doesn't have the closing </select>.  This
	// causes problems with HTMLTidy
	input = [input stringByReplacingOccurrencesOfRegex: @"</option>\\s*\\n\\s*</td>" withString: @"</option></select></td>"];
	
	return input;
}

@end