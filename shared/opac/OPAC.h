#import <Foundation/Foundation.h>

// These are required by all inherited clases so we import them here for convienience
#import "Util.h"
#import "SharedExtras.h"
#import "URL.h"
#import "Debug.h"
#import "Loan.h"
#import "Hold.h"
#import "Browser.h"
#import "DataStore.h"
#import "Test.h"
#import "RegexKitLite.h"
#import "NSScannerSettings.h"
#import "DateParser.h"
#import "JSON.h"

@protocol OPAC

- (BOOL) update;

@end

@interface OPAC : NSObject
{
	NSDictionary		*properties;
	NSString			*name;
	URL					*catalogueURL;
	URL					*myAccountCatalogueURL;
	URL					*webPageURL;
	URL					*openingHoursURL;
	NSArray				*loansTableColumns;
	NSArray				*holdsTableColumns;

	LibraryCard			*libraryCard;

	DateParser			*dateParser;
	DataStore			*dataStore;
	
	NSUInteger			authenticationCount;
	NSDictionary		*extraAuthenticationAttributes;
	
	NSString			*authentication1Title;
	NSString			*authentication2Title;
	NSString			*authentication3Title;
	
	NSString			*authentication1Key;
	NSString			*authentication2Key;
	NSString			*authentication3Key;
	
	BOOL				authentication1IsSecure;
	BOOL				authentication2IsSecure;
	BOOL				authentication3IsSecure;

	BOOL				authentication1Required;
	BOOL				authentication2Required;
	BOOL				authentication3Required;

	BOOL				authentication1IsNumber;
	BOOL				authentication2IsNumber;
	BOOL				authentication3IsNumber;
	
	Browser				*browser;
	NSScannerSettings	*scannerSettings;
	
	NSUInteger			loansCount;
	NSUInteger			holdsCount;
}

@property(retain)				NSDictionary	*properties;
@property(retain)				NSString		*name;
@property(retain)				URL				*catalogueURL;
@property(retain)				URL				*myAccountCatalogueURL;
@property(retain)				URL				*webPageURL;
@property(retain)				URL				*openingHoursURL;
@property(retain)				NSArray			*loansTableColumns;
@property(retain)				NSArray			*holdsTableColumns;
@property(retain)				NSString		*dateFormat;

@property(retain)				LibraryCard		*libraryCard;

@property(readonly)				NSUInteger		authenticationCount;
@property(readonly)				NSMutableDictionary	*authenticationAttributes;
@property(retain)				NSDictionary	*extraAuthenticationAttributes;

@property(retain)				NSString		*authentication1Title;
@property(retain)				NSString		*authentication2Title;
@property(retain)				NSString		*authentication3Title;

@property(retain)				NSString		*authentication1Key;
@property(retain)				NSString		*authentication2Key;
@property(retain)				NSString		*authentication3Key;

@property(readonly)				BOOL			authentication1IsSecure;
@property(readonly)				BOOL			authentication2IsSecure;
@property(readonly)				BOOL			authentication3IsSecure;

@property(readonly)				BOOL			authentication1Required;
@property(readonly)				BOOL			authentication2Required;
@property(readonly)				BOOL			authentication3Required;

@property(readonly)				BOOL			authentication1IsNumber;
@property(readonly)				BOOL			authentication2IsNumber;
@property(readonly)				BOOL			authentication3IsNumber;

@property(readonly)				NSUInteger		loansCount;
@property(readonly)				NSUInteger		holdsCount;

+ (OPAC<OPAC> *) opacForProperties: (NSDictionary *) properties;
+ (OPAC<OPAC> *) opacForIdentifier: (NSString *) identifier;
+ (OPAC<OPAC> *) opacForLibraryCard: (LibraryCard *) libraryCard;
+ (OPAC<OPAC> *) eBookOpacForIdentifier: (NSString *) identifier;
+ (OPAC<OPAC> *) eBookOpacForLibraryCard: (LibraryCard *) libraryCard;
- (id) initWithProperties: (NSDictionary *) properties;
- (NSDictionary *) properties;
- (BOOL) authenticationOK;
- (Loan *) addLoan: (NSDictionary *) row;
- (void) addLoans: (NSArray *) rows;
- (void) addEBookLoans: (NSArray *) rows;
- (Hold *) addHold: (NSDictionary *) row;
- (void) addHolds: (NSArray *) rows;
- (void) addEBookHolds: (NSArray *) rows;
- (void) addHoldsReadyForPickup: (NSArray *) rows;
- (NSDate *) parseDueDate: (NSString *) dueDateString;
- (NSString *) normaliseTitle: (NSString *) title;
- (NSString *) normaliseAuthor: (NSString *) author;
- (BOOL) myAccountEnabled;
- (BOOL) downloadHoldsEnabled;

@end