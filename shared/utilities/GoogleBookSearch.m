#import "GoogleBookSearch.h"
#import "SharedExtras.h"
#import "URL.h"
#import "RegexKitLite.h"

// Constants -------------------------------------------------------------------

static const NSString *base = @"http://books.google.com/books/feeds/volumes?max-results=2";

// -----------------------------------------------------------------------------

@implementation GoogleBookSearch

+ (GoogleBookSearch *) googleBookSearch
{
	return [[[GoogleBookSearch alloc] init] autorelease];
}

- (URL *) searchURLForTitle: (NSString *) title author: (NSString *) author isbn: (NSString *) isbn
{
	title		= [[self normaliseTitle: title] URLEncode];
	author		= [[self normaliseAuthor: author] URLEncode];
	isbn		= [isbn URLEncode];
	
	URL *url;
	if (isbn && [isbn length] > 0)
	{
		url = [URL URLWithFormat: @"%@&q=isbn:%@", base, isbn];
	}
	else if (author && [author length] > 0)
	{
		url = [URL URLWithFormat: @"%@&q=intitle:%@+inauthor:%@", base, title, author];
	}
	else
	{
		url = [URL URLWithFormat: @"%@&q=intitle:%@", base, title];
	}
					
	return url;
}

- (ImageBridge *) imageForURL: (URL *) url
{
	NSString *data = [url download];

	NSString *href = [data stringByMatching: @"<link rel='http://schemas.google.com/books/2008/thumbnail' type='[^']+' href='([^']+)'" capture: 1];
	while (href)
	{
		// Convert &amp; -> & because the download blows up if &amp; is used.
		// Also disable the page curl effect
		href = [href stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"];
		href = [href stringByDeletingOccurrencesOfString: @"edge=curl&"];
		URL *imageURL = [URL URLWithString: href];
		return [ImageBridge imageWithData: [NSData dataWithContentsOfURL: imageURL]];
	}
	
	return nil;
}

- (URL *) infoLinkForURL: (URL *) url
{
	NSString *data = [url download];

	NSString *href = [data stringByMatching: @"<link rel='http://schemas.google.com/books/2008/info' type='[^']+' href='([^']+)'" capture: 1];
	while (href)
	{
		// Convert &amp; -> & because the download blows up if &amp; is used.
		// Also disable the page curl effect
		href = [href stringByReplacingOccurrencesOfString: @"&amp;" withString: @"&"];
		return [URL URLWithString: href];
	}
	
	return nil;
}

// -----------------------------------------------------------------------------
//
// Some titles include the sub title and that prevents the Amazon search
// from working.  Look for long sub titles and remove them
//
// -----------------------------------------------------------------------------
- (NSString *) normaliseTitle: (NSString *) title
{
	if ([title hasSubString: @":"])
	{
		NSString *shortTitle = [title stringUptoLast: @":"];
		int subTitleLength = [title length] - [shortTitle length];
		if (subTitleLength > 15)
		{
			title = shortTitle;
		}
	}
	
	return title;
}

// -----------------------------------------------------------------------------
//
// Make the author's name more searchable by:
//		* stripping out the year of birth by removing numbers
//		* stripping out initials by remove single letter characters
//		* stripping text in brackets.  They are the initials and Amazon doesn't
//		  know what they are
//
// Examples:
//		Stone, Andrew, 1971-			->			Stone Andrew
//		Alexander, G. C. A.				->			Alexander
//		William Cook (William Glen)		->			William Cook
//
// -----------------------------------------------------------------------------
- (NSString *) normaliseAuthor: (NSString *) author
{
	if (author == nil) return @"";

	// Strip out bracketed text
	author = [author stringByDeletingOccurrencesOfRegex: @"\\([^)]+\\)"];

	NSMutableArray *normalisedWords = [NSMutableArray array];
	
	NSArray *words = [author words];
	for (NSString *word in words)
	{
		// Ignore numbers to remove birth dates.  Ignore single characters to
		// ignore initials
		if ([word isNumber] == NO && [word length] > 1)
		{
			[normalisedWords addObject: word];
		}
	}
	
	return [normalisedWords componentsJoinedByString: @" "];
}

@end