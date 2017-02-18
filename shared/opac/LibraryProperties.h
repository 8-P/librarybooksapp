#import <Foundation/Foundation.h>
#import "DataStore.h"

@interface LibraryProperties : NSObject
{
	DataStore *dataStore;
}

// -----------------------------------------------------------------------------

@property(readonly) int bundleVersion;
@property(readonly) int installedVersion;

// -----------------------------------------------------------------------------

+ (LibraryProperties *) libraryProperties;
- (NSMutableDictionary *) libraryPropertiesForIdentifier: (NSString *) identifier;
- (void) loadDefaultLibraries: (NSString *) path;
- (void) loadProperties: (NSDictionary *) properties type: (NSString *) type;
- (void) loadProperty: (NSDictionary *) p identifier: (NSString *) identifier registeredPaths: (NSMutableDictionary *) registeredPaths type: (NSString *) type;
- (void) loadCustomLibraries;
- (void) loadGenericLibraries;
- (void) quickUpdate;
- (void) update;
- (NSDictionary *) checkForUpdate;
- (void) clearCache;

@end