#import <Foundation/Foundation.h>
#import "Loan.h"
#import "Hold.h"
#import "LibraryCard.h"
#import "History.h"
#import "Location.h"
#import "OrderedDictionary.h"

@interface DataStore : NSObject
{
	NSManagedObjectModel			*managedObjectModel;
    NSManagedObjectContext			*managedObjectContext1;
	NSManagedObjectContext			*managedObjectContext2;	    
    NSPersistentStoreCoordinator	*persistentStoreCoordinator;
	NSThread						*context2Thread;
}

// -----------------------------------------------------------------------------

@property (nonatomic, retain, readonly) NSManagedObjectModel			*managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext			*managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator	*persistentStoreCoordinator;
@property (atomic, retain)				NSThread						*context2Thread;

// -----------------------------------------------------------------------------

+ (BOOL) isMigrationNecessary;
+ (DataStore *) sharedDataStore;
- (void) update;
- (void) downloadImage: (Image *) image;
- (void) sendReloadNotification;
- (BOOL) deleteIfBadLibraryCard: (LibraryCard *) libraryCard;

- (NSArray *) selectLibraryCards;
- (NSArray *) selectAllLibraryCards;
- (NSArray *) libraryCardsNamed: (NSString *) name ignoringLibraryCard: (LibraryCard *) libraryCard;
- (void) deleteLibraryCard: (LibraryCard *) libraryCard;
- (NSString *) libraryCardNameForOrdering: (int) ordering;
- (int) maxLibraryCardOrdering;
- (BOOL) authenticationOKForAllLibraryCards;

- (NSArray *) loansForLibraryCard: (LibraryCard *) libraryCard eBook: (BOOL) eBook;
- (OrderedDictionary *) loansGroupedByDueDateForLibraryCard: (LibraryCard *) libraryCard;
- (void) deleteAllLoansForLibraryCard: (LibraryCard *) libraryCard;
- (int) countOverdueLoans;
- (int) countLoansDueBefore: (NSDate *) date;
- (int) countLoans;
- (OrderedDictionary *) dueDatesForActiveLibraries;
- (void) prepareLoansForLibraryCard: (LibraryCard *) libraryCard;
- (void) commitLoansForLibraryCard: (LibraryCard *) libraryCard;
- (void) commitEBookLoansForLibraryCard: (LibraryCard *) libraryCard;

- (NSArray *) holdsForLibraryCard: (LibraryCard *) libraryCard readyForPickup: (BOOL) readyForPickup eBook: (BOOL) eBook;
- (void) deleteAllHoldsForLibraryCard: (LibraryCard *) libraryCard;
- (void) prepareHoldsForLibraryCard: (LibraryCard *) libraryCard;
- (void) commitHoldsForLibraryCard: (LibraryCard *) libraryCard;
- (void) commitEBookHoldsForLibraryCard: (LibraryCard *) libraryCard;
- (int) countReadyForPickupHolds;
- (int) countHolds;

- (History *) selectHistoryForLoan: (Loan *) loan month: (NSDate *) month;
- (NSArray *) selectHistoryForMonth: (NSDate *) month;
- (NSArray *) selectHistoryMonths;
- (int) countHistory;

- (NSArray *) locationsNearLocation: (CLLocation *) location;
- (void) deleteAllLocations;

- (Library *) selectLibraryForIdentifier: (NSString *) identifier;
- (void) deleteAllLibraries;
- (void) deleteAllLibraryDrillDownItems;
- (void) deleteLibraryDrillDownItemsWithType: (NSString *) type;
- (void) deleteLibrariesWithType: (NSString *) type;
- (NSArray *) libraryDrillDownItemForPath: (NSString *) path type: (NSString *) type;
- (NSArray *) selectLibrariesInUse;
- (int) countLibraries;
- (int) countLibrariesWithType: (NSString *) type;

- (int) countEntityNamed: (NSString *) entityName predicate: (NSPredicate *) predicate;
- (NSArray *) objectsForentityNamed: (NSString *) entityName predicate: (NSPredicate *) predicate;
- (void) deleteAll: (NSString *) entityName;
- (void) deleteAll: (NSString *) entityName predicate: (NSPredicate *) predicate;

- (Image *) selectImageForURI: (NSString *) uri;
- (NSArray *) imagesInUse;
- (void) deleteUnusedImages;

- (void) save;
- (void) rollback;
- (void) logError:(NSError *) error withSummary: (NSString *) summaryFormat, ...;

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
- (NSFetchedResultsController *) fetchLibraryCards;
- (NSFetchedResultsController *) fetchLoans;
- (NSFetchedResultsController *) fetchHolds;
- (NSFetchedResultsController *) fetchHistory;
- (NSFetchedResultsController *) fetchLibraryDrillDownItemForPath: (NSString *) path;
#endif

@end