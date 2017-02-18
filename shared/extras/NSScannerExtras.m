#import "NSScannerExtras.h"
#import "SharedExtras.h"
#import "Debug.h"
#import "RegexKitLite.h"
#import "NSScannerSettings.h"

#pragma GCC diagnostic ignored "-Wunused-value"

@implementation NSScanner (NSScannerExtras)

+ (NSScanner *) scannerWithString: (NSString *) string
{
	// Strip out <script></script> from the string
	if ([NSScannerSettings sharedSettings].ignoreHTMLScripts)
	{
		string = [string stringWithoutHTMLScripts];
	}

	NSScanner *scanner = [[[NSScanner alloc] initWithString: string] autorelease];
	[scanner setCaseSensitive: NO];
	return scanner;
}

// -----------------------------------------------------------------------------
//
// Scan up to the given string.
//
// Note that this function will return NO if you are already position just
// before the given string.
//
// -----------------------------------------------------------------------------
- (BOOL) scanUpToString: (NSString *) stopString
{
	return [self scanUpToString: stopString intoString: nil];
}

// Scan pass the given string.
- (BOOL) scanPassString: (NSString *) stopString
{	
	unsigned originalScanLocation = [self scanLocation];
	
	[self scanUpToString: stopString];
	if ([self scanString: stopString intoString: nil] == YES)
	{
		return YES;
	}
	
	// We failed to find a match so we revert to the original scan location
	[self setScanLocation: originalScanLocation];
	return NO;
}

- (BOOL) scanFromString: (NSString *) leftString upToString: (NSString *) rightString intoString: (NSString **) stringValue
{
	unsigned originalScanLocation = [self scanLocation];
	
	if ([self scanPassString: leftString] == YES)
	{
		// This is a bit tricky because the scanUpToString function will return
		// NO if the rightString is at the current position
		if ([self scanString: rightString intoString: nil] == YES)
		{
			*stringValue = @"";
			[self setScanLocation: [self scanLocation] - [rightString length]];
			return YES;
		}
		if ([self scanUpToString: rightString intoString: stringValue] == YES) return YES;
	}
	
	// We failed to find a match so we revert to the original scan location
	[self setScanLocation: originalScanLocation];
	return NO;
}

- (BOOL) scanFromString: (NSString *) leftString upToString: (NSString *) rightString intoFloat: (float *) value
{
	NSString *stringValue;
	if ([self scanFromString: leftString upToString: rightString intoString: &stringValue] == YES)
	{
		*value = [stringValue floatValue];
		return YES;
	}
	
	return NO;
}

// -----------------------------------------------------------------------------
//
// Scan for a matching regular expression.
//
//		* Advances the scan location when a match is found.
//
// -----------------------------------------------------------------------------
- (BOOL) scanRegex: (NSString *) regex capture: (NSInteger) capture intoString: (NSString **) stringValue
{
	NSString *string		= [self string];
	NSUInteger scanLocation	= [self scanLocation];

	NSRange searchRange = NSMakeRange(scanLocation, [string length] - scanLocation);
	NSRange range = [string rangeOfRegex: regex options: RKLDotAll inRange: searchRange capture: 0 error: nil];
	if (range.location == NSNotFound)
	{
		return NO;
	}

	// Grab the matching string
	*stringValue = [[string substringWithRange: range] stringByMatching: regex options: RKLDotAll inRange: NSMakeRange(0, range.length) capture: capture error: nil];

	// Advance the scan location
	scanLocation = MIN(range.location + range.length, [string length] - 1);
	[self setScanLocation: scanLocation];
	
	return YES;
}

// =============================================================================
#pragma mark -
#pragma mark HTML parsing

// -----------------------------------------------------------------------------
//
// Returns these form parameters:
//
//		* hidden input parameters
//		* The submit button parameter.  Most systems don't need this but is
//		  used by the Polaris system.  The browser always submits this value
//		  so it is good form to follow
//
// -----------------------------------------------------------------------------
- (NSMutableDictionary *) hiddenFormAttributes
{
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	NSMutableDictionary *submits	= [NSMutableDictionary dictionary];
	NSUInteger submitsCount			= 0;

	NSString *element;
	while ([self scanFromString: @"<input" upToString: @">" intoString: &element])
	{
		if ([element hasCaseInsensitiveSubString: @"type=\"hidden\""]
			|| [element hasCaseInsensitiveSubString: @"type='hidden'"]
			|| [element hasCaseInsensitiveSubString: @"type=hidden"])
		{
			NSScanner *scanner = [NSScanner scannerWithString: element];
			[scanner setCaseSensitive: NO];
			
			NSString *name = nil;
			[scanner scanFromString: @"name=\"" upToString: @"\"" intoString: &name]
				|| [scanner scanFromString: @"name='" upToString: @"'" intoString: &name]
				|| [scanner scanFromString: @"name=" upToString: @" " intoString: &name]
				|| [scanner scanFromString: @"name=" upToString: @"" intoString: &name];
			if (name == nil) continue;

			NSString *value = nil;
			[scanner setScanLocation: 0];
			[scanner scanFromString: @"value=\"" upToString: @"\"" intoString: &value]
				|| [scanner scanFromString: @"value='" upToString: @"'" intoString: &value]
				|| [scanner scanFromString: @"value=" upToString: @" " intoString: &value]
				|| [scanner scanFromString: @"value=" upToString: @"" intoString: &value];
			if (value == nil) continue;

			[attributes setObject: value forKey: name];
		}
		
		// Handle submit
		if ([element hasCaseInsensitiveSubString: @"type=\"submit\""]
			|| [element hasCaseInsensitiveSubString: @"type='submit'"]
			|| [element hasCaseInsensitiveSubString: @"type=submit"])
		{
			NSScanner *scanner = [NSScanner scannerWithString: element];
			[scanner setCaseSensitive: NO];
			
			NSString *name = nil;
			[scanner scanFromString: @"name=\"" upToString: @"\"" intoString: &name]
				|| [scanner scanFromString: @"name='" upToString: @"'" intoString: &name]
				|| [scanner scanFromString: @"name=" upToString: @" " intoString: &name]
				|| [scanner scanFromString: @"name=" upToString: @"" intoString: &name];
			if (name == nil) continue;

			NSString *value = nil;
			[scanner setScanLocation: 0];
			[scanner scanFromString: @"value=\"" upToString: @"\"" intoString: &value]
				|| [scanner scanFromString: @"value='" upToString: @"'" intoString: &value]
				|| [scanner scanFromString: @"value=" upToString: @" " intoString: &value]
				|| [scanner scanFromString: @"value=" upToString: @"" intoString: &value];
			if (value == nil) continue;

			// Handle multiple submits with the same key value, e.g. us.ny.QueensLibrary:
			//
			//		<input type="submit" name="op" value="Log In"/>
			//		<input type="submit" name="op" value="Cancel"/>
			id existingValue = [submits objectForKey: name];
			if (existingValue && [existingValue isKindOfClass: [NSString class]])
			{
				[submits setObject: [NSArray arrayWithObjects: existingValue, value, nil] forKey: name];
			}
			else if (existingValue && [existingValue isKindOfClass: [NSArray class]])
			{
				[submits setObject: [existingValue arrayByAddingObject: value] forKey: name];
			}
			else
			{
				[submits setObject: value forKey: name];
			}
			
			submitsCount++;
		}
	}
	
//	while ([self scanFromString: @"<input" upToString: @">" intoString: &element])
//	{
//	}
	
	// Handle forms with mutiple submit buttons
	//
	//		* Don't include the submit text.  Let the backend choose the default.
	//		* Contra-Consta, CA, US library's login form has two buttons.  One
	//		  for login and the other for forgot password.
	if (submitsCount == 1)
	{
		[attributes addEntriesFromDictionary: submits];
	}
	else if (submitsCount > 1)
	{
		[Debug logDetails: [submits description] withSummary: @"multiple submit attributes, ignoring"];
	}

	return attributes;
}

// -----------------------------------------------------------------------------
//
// Returns the src for an anchor tag with the specified label
//
// TODO: Use NSXMLElement
//
// -----------------------------------------------------------------------------
- (NSString *) linkForLabel: (NSString *) label
{
	unsigned originalScanLocation = [self scanLocation];

	HTMLElement *element;
	while ([self scanNextElementWithName: @"a" intoElement: &element])
	{
		if ([[element.value stringToHTML] hasCaseInsensitiveSubString: label]
			|| [[element.attributes objectForKey: @"alt"] hasCaseInsensitiveSubString: label]
			|| [[element.attributes objectForKey: @"title"] hasCaseInsensitiveSubString: label])
		{
			NSString *link = [element.attributes objectForKey: @"href"];
			if (link != nil) return link;
		}
	}
	
	// Search buttons as well
	[self setScanLocation: originalScanLocation];
	while ([self scanNextElementWithName: @"input" attributeKey: @"type" attributeValue: @"button" intoElement: &element])
	{
		if ([[element.attributes objectForKey: @"value"] hasCaseInsensitiveSubString: label])
		{
			NSString *onclick = [element.attributes objectForKey: @"onclick"];
			NSString *link = [onclick stringByMatching: @"window.location\\s*=\\s*(.*)" capture: 1];
			if (link)
			{
				link = [link stringWithoutQuotes];
				return link;
			}
		}
	}
	
	// Restore the original scan location because we didn't find a match
	[self setScanLocation: originalScanLocation];
	return nil;
}

- (NSString *) linkForHrefRegex: (NSString *) regex
{
	unsigned originalScanLocation = [self scanLocation];

	HTMLElement *element;
	while ([self scanNextElementWithName: @"a" intoElement: &element])
	{
		NSString *href = [element.attributes objectForKey: @"href"];
		if ([href isMatchedByRegex: regex])
		{
			if (href != nil) return href;
		}
	}
	
	// Restore the original scan location because we didn't find a match
	[self setScanLocation: originalScanLocation];
	return nil;
}

#if 0
- (NSString *) linkForLabelOld: (NSString *) label
{
	unsigned originalScanLocation = [self scanLocation];

	NSString *element;
	while ([self scanFromString: @"<a" upToString: @">" intoString: &element])
	{
		NSString *text = nil;
		[self scanFromString: @">" upToString: @"</a>" intoString: &text];
		if (text == nil) continue;
		text = [text stringWithoutHTML];

		if ([text hasCaseInsensitiveSubString: label] == YES)
		{
			NSScanner *scanner = [NSScanner scannerWithString: element];
			[scanner setCaseSensitive: NO];
			
			NSString *link = nil;
			[scanner scanFromString: @"href=\"" upToString: @"\"" intoString: &link]
				|| [scanner scanFromString: @"href='" upToString: @"'" intoString: &link]
				|| [scanner scanFromString: @"href=" upToString: @" " intoString: &link]
				|| [scanner scanFromString: @"href=" upToString: @"" intoString: &link];

			if (link != nil) return link;
		}
	}
	
	// Restore the original scan location because we didn't find a match
	[self setScanLocation: originalScanLocation];
	return nil;
}
#endif

- (BOOL) scanPassHead
{
	[self setScanLocation: 0];
	return [self scanPassElementWithName: @"head"];
}

- (HTMLElement *) head
{
	[self setScanLocation: 0];
	
	HTMLElement *element = nil;
	if ([self scanNextElementWithName: @"head" intoElement: &element])
	{
		return element;
	}
	else
	{
		return nil;
	}
}

- (BOOL) scanNextElementWithName: (NSString *) name intoElement: (HTMLElement **) element
{
	unsigned originalScanLocation = [self scanLocation];

	NSString *elementPrefix = [NSString stringWithFormat: @"<%@", name];
	NSString *elementSuffix = [NSString stringWithFormat: @"</%@>", name];

	NSString *elementString = nil;
	if ([self scanFromString: elementPrefix upToString: @">" intoString: &elementString])
	{
		// Grab the value if we have element tag with a value.  We handle nested
		// tags by taking in the inner most value.
		//
		//		* Ignores tags like <tag .../>
		//		* Ignores tags without closing like <input>.  This is needed for
		//		  pages that have skipped HTMLTidy
		NSMutableString *value = nil;
		if ([elementString hasSuffix: @"/"] == NO && [name isEqualToString: @"input"] == NO)
		{
			[self scanFromString: @">" upToString: elementSuffix intoString: &value];

			// Handle nested elements.  Ignore non-nestable elements
			if ([name isEqualToString: @"a"] == NO)
			{
				// Figure out how many nested elements there are.
				//
				//		* Ignore stuff in <script></script>
				int occurances = [[value stringWithoutHTMLScripts] countOccurancesOfCaseInsensitiveSubString: elementPrefix];
				if (occurances > 0)
				{
					NSMutableString *newValue = [[value mutableCopy] autorelease];
					for (int i = 0; i < occurances; i++)
					{
						NSString *appendValue = @"";
						if ([self scanFromString: elementSuffix upToString: elementSuffix intoString: &appendValue])
						{
							[newValue appendString: elementSuffix];
							[newValue appendString: appendValue];
							
							// Deal with more nested elements
							occurances += [appendValue countOccurancesOfCaseInsensitiveSubString: elementPrefix];
						}
					}
					
					value = newValue;
				}
			}
		}
		
		HTMLElement *newElement = [HTMLElement element];
		*element = newElement;
		newElement.value = value;

		// Parse the tag for the attributes
		NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
		newElement.attributes = attributes;
		
		int i;
		for (i = 0; i < [elementString length];)
		{
			// Skip blank spaces
			for (; i < [elementString length] && [elementString characterAtIndex: i] == ' '; i++);
			
			// Grab the attribute
			NSMutableString *attribute = [NSMutableString string];
			for (;i < [elementString length]; i++)
			{
				unichar c = [elementString characterAtIndex: i];
				if (c == ' ' || c == '=') break;
				
				[attribute appendFormat: @"%C", c];
			}
			
			// Skip blank spaces
			for (;i < [elementString length] && [elementString characterAtIndex: i] == ' '; i++);
			
			// Grab the value.  Ignore keyless attributes
			if (i < [elementString length] && [elementString characterAtIndex: i] == '=')
			{
				// Skip over the equals "=" and and trailing whitespaces
				i++;
				for (;i < [elementString length] && [elementString characterAtIndex: i] == ' '; i++);
				
				unichar quote = ' ';
				unichar c = [elementString characterAtIndex: i];
				if (c == '"' || c == '\'')
				{
					quote = c;
					i++;
				}
				
				NSMutableString *value = [NSMutableString string];
				for (;i < [elementString length]; i++)
				{
					c = [elementString characterAtIndex: i];
					if (c == quote)
					{
						i++;
						break;
					}
					
					[value appendFormat: @"%C", c];
				}
				
				// Yay! We have an attribute
				[attributes setObject: value forKey: attribute];
			}
		}
		
		return YES;
	}
	
	// Restore the original scan location because we didn't find a match
	[self setScanLocation: originalScanLocation];
	return NO;
}

// -----------------------------------------------------------------------------
//
// Scan for the first element matching one of the names.
//
//		* Added to handle searching for <td> or <th> elements.
//
// -----------------------------------------------------------------------------
- (BOOL) scanNextElementWithNames: (NSArray *) names intoElement: (HTMLElement **) element
{
	unsigned originalScanLocation	= [self scanLocation];
	BOOL found						= NO;
	NSInteger min					= INT_MAX;
	HTMLElement *minElement			= nil;
	NSInteger minScanLocation;
	
	for (NSString *name in names)
	{
		[self setScanLocation: originalScanLocation];
	
		HTMLElement *tempElement;
		if ([self scanNextElementWithName: name intoElement: &tempElement])
		{
			NSInteger diff = [self scanLocation] - originalScanLocation;
			if (diff < min)
			{
				minElement		= [[tempElement copy] autorelease];
				minScanLocation = [self scanLocation];
			}
			
			found = YES;
		}
	}
	
	if (found)
	{
		*element = minElement;
		[self setScanLocation: minScanLocation];
		return YES;
	}
	else
	{
		[self setScanLocation: originalScanLocation];
		return NO;
	}
}

- (BOOL) scanNextElementWithName: (NSString *) name attributes: (NSDictionary *) attributes
	intoElement: (HTMLElement **) element recursive: (BOOL) recursive
{
	HTMLElement *tempElement;
	unsigned originalScanLocation = [self scanLocation];

	while ([self scanNextElementWithName: name intoElement: &tempElement])
	{
		// Match the attributes
		BOOL found = YES;
		for (NSString *key in attributes)
		{
			NSString *value			= [tempElement.attributes objectForKey: key];
			NSString *matchValue	= [attributes objectForKey: key];
			
			// Handle regex matching
			//
			//		* Regexs are indicated by a "REGEX:" prefix
			BOOL isRegex = [matchValue hasPrefix: @"REGEX:"];
			if (isRegex) matchValue = [matchValue stringByDeletingOccurrencesOfRegex: @"^REGEX:"];
			
			if (value == nil
				|| (isRegex == NO && [value isEqualToString: matchValue] == NO)
				|| (isRegex       && [value isMatchedByRegex: matchValue] == NO))
			{
				found = NO;
				break;
			}
		}
		
		// Try search for the element recursively
		if (recursive && found == NO)
		{
			NSScanner *recursiveScanner = tempElement.scanner;
			found = [recursiveScanner scanNextElementWithName: name attributes: attributes
				intoElement: &tempElement recursive: YES];
			
			// Set the scan location
			if (found) [self setScanLocation: [self scanLocation] - [[recursiveScanner string] length] + [recursiveScanner scanLocation]];
		}
		
		if (found)
		{
			*element = [[tempElement copy] autorelease];
			return YES;
		}
	}
	
	[self setScanLocation: originalScanLocation];
	return NO;
}

- (BOOL) scanNextElementWithName: (NSString *) name attributeKey: (NSString *) key attributeValue: (NSString *) value
	intoElement: (HTMLElement **) element recursive: (BOOL) recursive
{
	NSDictionary *attributes = [NSDictionary dictionaryWithObject: value forKey: key];
	return [self scanNextElementWithName: name attributes: attributes intoElement: element recursive: recursive];
}

- (BOOL) scanNextElementWithName: (NSString *) name attributes: (NSDictionary *) attributes
	intoElement: (HTMLElement **) element
{
	return [self scanNextElementWithName: name attributes: attributes intoElement: element recursive: NO];
}

- (BOOL) scanNextElementWithName: (NSString *) name attributeKey: (NSString *) key attributeValue: (NSString *) value
	intoElement: (HTMLElement **) element
{
	return [self scanNextElementWithName: name attributeKey: key attributeValue: value intoElement: element recursive: NO];
}

- (BOOL) scanNextElementWithName: (NSString *) name attributeKey: (NSString *) key attributeRegex: (NSString *) regex
	intoElement: (HTMLElement **) element
{
	NSString *value = [NSString stringWithFormat: @"REGEX:%@", regex];
	return [self scanNextElementWithName: name attributeKey: key attributeValue: value intoElement: element recursive: YES];
}

// -----------------------------------------------------------------------------
//
// Find the next element containing the search value.
//
// It will dig in recursively until it finds the deepest element.
//
// -----------------------------------------------------------------------------
- (BOOL) scanNextElementWithName: (NSString *) name regexValue: (NSString *) value
	intoElement: (HTMLElement **) element
{
	HTMLElement *tempElement;
	BOOL found						= NO;
	unsigned originalScanLocation	= [self scanLocation];

	NSScanner *scanner = self;
	while ([scanner scanNextElementWithName: name intoElement: &tempElement])
	{
		// Match the attributes
		if ([tempElement.value isMatchedByRegex: value])
		{
			scanner		= tempElement.scanner;
			*element	= [[tempElement copy] autorelease];
			found		= YES;
		}
	}
	
	if (found == NO) [self setScanLocation: originalScanLocation];
	return found;
}

- (BOOL) scanPassElementWithName: (NSString *) name
{
	HTMLElement *element;
	return [self scanNextElementWithName: name intoElement: &element];
}

- (BOOL) scanPassElementWithName: (NSString *) name attributeKey: (NSString *) key attributeValue: (NSString *) value
{
	HTMLElement *element;
	return [self scanNextElementWithName: name attributeKey: key attributeValue: value intoElement: &element];
}

- (BOOL) scanPassElementWithName: (NSString *) name regexValue: (NSString *) regexValue
{
	HTMLElement *element;
	return [self scanNextElementWithName: name regexValue: regexValue intoElement: &element];
}

// =============================================================================
#pragma mark -
#pragma mark Table scanning

// -----------------------------------------------------------------------------
//
// Parse a table for the row values.
//
// -----------------------------------------------------------------------------
- (NSArray *) tableWithColumns: (NSArray *) columns ignoreRows: (NSArray *) ignoreRows delegate: (id) delegate ignoreFirstRow: (BOOL) ignoreFirstRow
{
	[Debug logDetails: [self string] withSummary: @"Parsing table"];

	NSMutableArray *rows		= [NSMutableArray array];
	BOOL columnCountMustMatch	= [NSScannerSettings sharedSettings].columnCountMustMatch;
	BOOL ignoreTableHeaderCells = [NSScannerSettings sharedSettings].ignoreTableHeaderCells;

	HTMLElement *element;
	int i = 1;
	while ([self scanNextElementWithName: @"tr" intoElement: &element])
	{
		NSScanner *rowScanner		= element.scanner;
		NSMutableDictionary *row	= [NSMutableDictionary dictionary];
		BOOL ok						= YES;
		NSString *debugSkipReason	= @"";
		NSString *debugDetails		= element.value;

		if (ignoreFirstRow && i == 1)
		{
			ok				= NO;
			debugSkipReason = @"skip first row";
		}

		NSArray *cellNames = (ignoreTableHeaderCells) ? [NSArray arrayWithObject: @"td"] : [NSArray arrayWithObjects: @"td", @"th", nil];
		for (NSString *column in columns)
		{
			// We only look for <td> elements and not <th>.  We assume that no 
			// important data will be in <th> elements
			if ([rowScanner scanNextElementWithNames: cellNames intoElement: &element] == NO)
			{
				// Don't parse this row if the column counts don't match
				if (columnCountMustMatch)
				{
					ok				= NO;
					debugSkipReason = @"column counts do not match";
				}
				
				break;
			}
			
			if ([column length] > 0)
			{
				// Check for ignored row values. We check both the attribute values
				// and element value
				if (ignoreRows)
				{
					for (NSString *ignoreValue in ignoreRows)
					{
						if ([element hasAttribute: ignoreValue]
							|| [element.value hasSubString: ignoreValue])
						{
							ok				= NO;
							debugSkipReason = [NSString stringWithFormat: @"matched ignore row value [%@]", ignoreValue];
							break;
						}
					}
				}
				
				if (delegate && [column hasSuffix: @":"])
				{
					// Handle selectors in the column specification.  Get the
					// selector to do the cell value parsing
					SEL selector = NSSelectorFromString(column);
					if ([delegate respondsToSelector: selector])
					{
						NSDictionary *values = [delegate performSelector: selector withObject: element.value];
						if (values)	[row addEntriesFromDictionary: values];
					}
				}
				else
				{
					// Clean up the value:
					//		* Details link appears in Fairfax County + Calgary SIRSI + Old Colony Network
					//		* "This item can be borrowed..." appears in us.ca.Santa Monica SIRSI
					NSString *value = element.value;
					value			= [value stringByDeletingOccurrencesOfRegex: @"<a href=\".*?\">(Details|Display Full Details)</a>"];
					value			= [value stringByDeletingOccurrencesOfRegex: @"<em>This item can be borrowed for \\S+ weeks?.</em>"];
					value			= [value stringWithoutHTML];
					
					[row setObject: value forKey: column];
				}
			}
		}

		if (ok)
		{
			[rows addObject: row];
			[Debug logDetails: debugDetails withSummary: @"Parsing row %d - ok", i];
		}
		else
		{
			[Debug logDetails: debugDetails withSummary: @"Parsing row %d - skip - %@", i, debugSkipReason];
		}
		
		i++;
	}

	[Debug space];
	return rows;
}

- (NSArray *) tableWithColumns: (NSArray *) columns ignoreRows: (NSArray *) ignoreRows delegate: (id) delegate
{
	return [self tableWithColumns: columns ignoreRows: ignoreRows delegate: delegate ignoreFirstRow: NO];
}

- (NSArray *) tableWithColumns: (NSArray *) columns ignoreRows: (NSArray *) ignoreRows
{
	return [self tableWithColumns: columns ignoreRows: ignoreRows delegate: nil ignoreFirstRow: NO];
}

- (NSArray *) tableWithColumns: (NSArray *) columns
{
	return [self tableWithColumns: columns ignoreRows: nil delegate: nil ignoreFirstRow: NO];
}

// -----------------------------------------------------------------------------
//
// Analyse a table for the title, author and due date columns headings.
//
//		* Handles colspan attributes.
//
// -----------------------------------------------------------------------------
- (NSArray *) analyseTableColumnsUsingDictionary: (OrderedDictionary *) dictionary
{	
	[Debug logDetails: [self string] withSummary: @"Analysing table columns"];

	unsigned originalScanLocation	= [self scanLocation];
	NSMutableArray *columns			= [NSMutableArray array];
	int minColumns					= [NSScannerSettings sharedSettings].minColumns;
	
	HTMLElement *element;
	while ([self scanNextElementWithName: @"tr" intoElement: &element])
	{
		[Debug logDetails: element.value withSummary: @"Parsing row"];
		
		// Convert <td> elements into <th>
		//
		//		* Do this to so we can handle mixtures of <td> and <th>
		NSScanner *rowScanner	= [NSScanner scannerWithString: [element.value stringByReplacingOccurrencesOfRegex: @"(</?)td" withString: @"$1th"]];
		int count				= 0;
		
		[columns removeAllObjects];
		
		// Look for the header row.  We look for a <th> and then fallback to a <td>
		while ([rowScanner scanNextElementWithName: @"th" intoElement: &element])
		{
			NSString *column = @"";
			for (NSString *key in dictionary)
			{
				if ([[element.value stringWithoutHTML] hasSubString: key])
				{
					column = [dictionary objectForKey: key];
					count++;
					break;
				}
			}
			
			// Handle "colspan"
			NSString *columnSpanString = [element.attributes objectForKey: @"colspan"];
			int columnSpan = (columnSpanString) ? [columnSpanString intValue] : 1;
			for (int i = 0; i < columnSpan; i++)
			{
				[columns addObject: column];
			}
		}

		if (count >= minColumns) break;
	}
	
	// Strip off empty columns at end.  We need to do this because some
	// catalogue systems don't included trailing <td></td> cells and it causes
	// the table parser to reject the row because the header and data row
	// column counts don't match
	for (int i = [columns count] - 1; i >= 0; i--)
	{
		if ([[columns objectAtIndex: i] isEqualToString: @""])
		{
			[columns removeObjectAtIndex: i];
		}
		else
		{
			break;
		}
	}
	
	// Handle fixed index replacements.  For example if you set the key to 0, the
	// first column index is replaced
	for (NSString *key in dictionary)
	{
		if ([key isNumber])
		{
			int index = [key intValue];
			if (0 <= index && index < [columns count])
			{
				NSString *column = [dictionary objectForKey: key];
				[columns replaceObjectAtIndex: index withObject: column];
			}
		}
	}
	
	[self setScanLocation: originalScanLocation];
	[Debug log: @"Columns [%@]", [columns componentsJoinedByString: @", "]];
	[Debug space];
	return ([columns count] > 0) ? columns : nil;
}

- (NSArray *) analyseLoanTableColumns
{
	NSScannerSettings *settings = [NSScannerSettings sharedSettings];
	if (settings.loanColumns)
	{
		[Debug log: @"Using loan column spec from settings"];
		return settings.loanColumns;
	}
	else
	{
		return [self analyseTableColumnsUsingDictionary: settings.loanColumnsDictionary];
	}
}

- (NSArray *) analyseHoldTableColumns
{
	NSScannerSettings *settings = [NSScannerSettings sharedSettings];
	if (settings.holdColumns)
	{
		[Debug log: @"Using hold column spec from settings"];
		return settings.holdColumns;
	}
	else
	{
		return [self analyseTableColumnsUsingDictionary: settings.holdColumnsDictionary];
	}
}

// -----------------------------------------------------------------------------
//
// Extract the data from a JavaScript data structure.  This is used by CARLweb.
//
// TODO: make more robust because currently it just searchings for data between
// "{" and "}" but it doesn't handle braces that are escaped.
//
// -----------------------------------------------------------------------------
- (NSArray *) javascriptWithKeyMapping: (NSDictionary *) mapping
{
	NSMutableArray *rows = [NSMutableArray array];
	
	NSString *string;
	while ([self scanFromString: @"{" upToString: @"}" intoString: &string])
	{
		NSMutableDictionary *row = [NSMutableDictionary dictionary];
		
		NSArray *keyValuePairs = [string componentsSeparatedByString: @","];
		for (NSString *pair in keyValuePairs)
		{
			NSArray *keyValue	= [pair componentsSeparatedByString: @":"];
			NSString *key		= [keyValue objectAtIndex: 0];
			NSString *value		= [keyValue objectAtIndex: 1];
			
			key		= [key stringByTrimmingWhitespace];
			key		= [mapping objectForKey: key];
			if (key)
			{
				value	= [value stringByTrimmingWhitespace];
				value	= [value stringWithoutQuotes];
				value	= [value stringWithoutHTML];
				
				[row setObject: value forKey: key];
			}
		}
		
		[rows addObject: row];
	}
	
	return rows;
}

// -----------------------------------------------------------------------------
//
// Generic analyser.
//
// -----------------------------------------------------------------------------
- (NSDictionary *) analyseUsingDictionary: (OrderedDictionary *) dictionary
{	
	NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity: [dictionary count]];
	NSString *debugDetails = @"";
	
	for (NSString *key in dictionary)
	{
		NSString *pattern = [dictionary objectForKey: key];
		NSString *value;
		
		if ([pattern hasPrefix: @"regex:"])
		{
			NSString *regex = [pattern stringByDeletingOccurrencesOfRegex: @"^regex:"];
			if ([self scanRegex: regex capture: 1 intoString: &value] == NO)
			{
				debugDetails = [NSString stringWithFormat: @"cannot match regex [%@]\n", regex];
				break;
			}
			
			value = [value stringWithoutHTML];
		}
		else if ([pattern hasPrefix: @"element:"])
		{
			HTMLElement *element;
			NSString *name = [pattern stringByDeletingOccurrencesOfRegex: @"^element:"];
			if ([self scanNextElementWithName: name intoElement: &element] == NO)
			{
				debugDetails = [NSString stringWithFormat: @"cannot match element [%@]\n", name];
				break;
			}
			
			value = [element.value stringWithoutHTML];
		}
		else
		{
			debugDetails = [NSString stringWithFormat: @"unknown pattern [%@]\n", pattern];
			break;
		}

		[values setObject: value forKey: key];
	}
	
	// Debug
	if ([debugDetails length] > 0)
	{
		[Debug logDetails: [self string] withSummary: @"Failed to analysed string - %@", debugDetails];
	}
	
	return values;
}

// -----------------------------------------------------------------------------
//
// Scan using a list of regular expressions.
//
// -----------------------------------------------------------------------------
- (NSDictionary *) dictionaryUsingRegexMapping: (OrderedDictionary *) mapping
{
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	
	for (NSString *key in mapping)
	{
		NSString *regex = [mapping objectForKey: key];
	
		NSString *string = nil;
		if ([self scanRegex: regex capture: 1 intoString: &string] && string)
		{
			[dictionary setObject: [string stringWithoutHTML] forKey: key];
		}
	}

	return dictionary;
}

- (NSScanner *) scannerForElementWithName: (NSString *) name attributeKey: (NSString *) key attributeRegex: (NSString *) regex
{
	HTMLElement *element = nil;
	if ([self scanNextElementWithName: name attributeKey: key attributeRegex: regex intoElement: &element])
	{
		return element.scanner;
	}
	
	return nil;
}

@end