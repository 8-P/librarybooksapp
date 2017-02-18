#import <Foundation/Foundation.h>

@interface OrderedDictionary : NSObject <NSFastEnumeration>
{
	NSMutableDictionary		*dictionary;
	NSMutableArray			*orderedKeys;
}

+ (OrderedDictionary *) dictionaryWithObjectsAndKeys: (id) firstObject, ...;
+ (OrderedDictionary *) dictionary;
- (id) initWithObjects: (NSArray *) objects forKeys: (NSArray *) keys;
- (void) addEntriesFromDictionary: (OrderedDictionary *) otherDictionary;
- (void) addObject: (id) object forKey: (id) key;
- (NSEnumerator *) keyEnumerator;
- (NSArray *) allKeys;
- (id) objectForKey: (id) key;
- (NSUInteger) count;

@end