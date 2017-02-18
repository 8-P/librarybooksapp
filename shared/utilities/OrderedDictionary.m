// =============================================================================
//
// Ordered NSDictionary.
//
// =============================================================================

#import "OrderedDictionary.h"

@implementation OrderedDictionary

// -----------------------------------------------------------------------------
//
// Got arg list handling code from http://cocotron.googlecode.com/svn/trunk/Foundation/NSDictionary/NSDictionary.m
// License is you can do whatever you want with it.
//
// -----------------------------------------------------------------------------
+ (OrderedDictionary *) dictionaryWithObjectsAndKeys: (id) firstObject, ...
{
	va_list arguments;
	va_start(arguments, firstObject);
	int count = 1;
	while (va_arg(arguments, id) != nil)
	{
		count++;
	}
	va_end(arguments);

	NSMutableArray *objects	= [NSMutableArray arrayWithCapacity: count / 2];
	NSMutableArray *keys	= [NSMutableArray arrayWithCapacity: count / 2];

	va_start(arguments, firstObject);

	[objects addObject: firstObject];
	[keys addObject:    va_arg(arguments, id)];

	for (int i = 1; i < count / 2; i++)
	{
		[objects addObject: va_arg(arguments, id)];
		[keys addObject:    va_arg(arguments, id)];
	}

	va_end(arguments);
	
	return [[[OrderedDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];
}

+ (OrderedDictionary *) dictionary
{
	NSArray *objects	= [NSArray array];
	NSArray *keys		= [NSArray array];
	return [[[OrderedDictionary alloc] initWithObjects: objects forKeys: keys] autorelease];
}

- (id) initWithObjects: (NSArray *) objects forKeys: (NSArray *) keys
{
	dictionary	= [[NSMutableDictionary dictionaryWithObjects: objects forKeys: keys] retain];
	orderedKeys = [[NSMutableArray arrayWithArray: keys] retain];
	
	return self;
}

// -----------------------------------------------------------------------------
//
// Append to the ordered dictionary:
//
//		* Existing keys have priority and are not updated.
//
// -----------------------------------------------------------------------------
- (void) addEntriesFromDictionary: (OrderedDictionary *) otherDictionary
{
	for (NSString *key in otherDictionary)
	{
		if ([dictionary objectForKey: key] == nil)
		{
			// Append the entry
			[dictionary setObject: [otherDictionary objectForKey: key] forKey: key];
			[orderedKeys addObject: key];
		}
	}
}

- (void) addObject: (id) object forKey: (id) key
{
	[dictionary setObject: object forKey: key];
	[orderedKeys addObject: key];
}

- (void) dealloc
{
	[dictionary release];
    [orderedKeys release];
    [super dealloc];
}

- (NSEnumerator *) keyEnumerator
{
    return [orderedKeys objectEnumerator];
}

- (NSArray *) allKeys
{
	return orderedKeys;
}

- (id) objectForKey: (id) key
{
	return [dictionary objectForKey: key];
}

- (NSUInteger) countByEnumeratingWithState: (NSFastEnumerationState *) state objects: (id *) stackbuf count: (NSUInteger) len
{
	return [orderedKeys countByEnumeratingWithState: state objects:stackbuf count: len];
}

- (NSUInteger) count
{
	return [orderedKeys count];
}

@end