#import "Hold.h"
#import "SharedExtras.h"
#import "DataStore.h"
#import "RegexKitLite.h"

@implementation Hold

@synthesize queuePositionString;
@dynamic title, author, isbn, queuePosition, pickupAt, readyForPickup, uriGoogleBookSearch,
	libraryCard, image, dummy, queueDescription, temporary, expiryDate, eBook;

// -----------------------------------------------------------------------------

+ (Hold *) hold
{
	NSManagedObjectContext *context = [DataStore sharedDataStore].managedObjectContext;
	return [NSEntityDescription insertNewObjectForEntityForName: @"Hold" inManagedObjectContext: context]; 
}

- (void) dealloc
{
	[queuePositionString release];
	[super dealloc];
}

- (void) calculate
{
	NSString *queueDescription = self.queueDescription;

	// Auto detect if the hold is ready for pickup
	//
	//		* Deal with strings like "Not ready" but checking
	//		  notReadyForPickupWords
	if ([queueDescription hasWords: [self notReadyForPickupWords]] == NO
		&& [queuePositionString hasWords: [self notReadyForPickupWords]] == NO)
	{
		if ([queueDescription hasWords: [self readyForPickupWords]]
			|| [queuePositionString hasWords: [self readyForPickupWords]])
		{
			self.readyForPickup	= [NSNumber numberWithBool: YES];
			self.queuePosition	= [NSNumber numberWithInt: 0];
		}
	}
	
	if ([self.readyForPickup boolValue] == NO && [self.queuePosition intValue] == -1)
	{
		// Autodetect the position
		NSString *string = [queueDescription stringByMatching: @"(\\d+) of \\d+" capture: 1];
		if (string)
		{
			// This on appears in the King County (Millenimum) system
			self.queuePosition = [NSNumber numberWithInt: [string intValue]];
		}
		else
		{
			// Fall back to niavely taking the first integer value
			NSArray *words = [queueDescription words];
			for (NSString *word in words)
			{
				int value = [word intValue];
				if (value > 0)
				{
					self.queuePosition = [NSNumber numberWithInt: value];
					break;
				}
			}
		}
	}
	
	// Don't save the queue description if it is the same as the queue position
	if ([self.queueDescription isEqualToString: [self.queuePosition stringValue]])
	{
		self.queueDescription = nil;
	}
}

- (NSArray *) notReadyForPickupWords
{
	return [NSArray arrayWithObjects:
		@"Not Ready", nil];
}

- (NSArray *) readyForPickupWords
{
	return [NSArray arrayWithObjects:
		@"Available",
		@"Ready",
		@"Ready.",
		@"Arrived",
		@"In Stock",
		@"Disponible",
		@"Awaiting pickup",
		@"Item waiting at",
		@"Held",					// Polaris - Central Library Consortium, OH
		@"waiting for you",			// SIRSI5 - us.ca.SantaCruzPublicLibraries
		@"abholbar",				// SISIS - de.ULBMunster
		@"Hold Shelf",
		@"Email notification sent",	// Overdrive
		@"On Hold",					// Polaris - [us.oh.DaytonMetroLibrary
		@"abholbereit",				// de.StaatsbibliothekZuBerlin
	nil];
}

- (NSString *) description
{
	return [NSString stringWithFormat:
		@"Hold: title [%@], author [%@], isbn [%@], queuePosition [%d], queueDescription [%@], pickupAt [%@], readyForPickup [%@], expiryDate [%@]",
		self.title, self.author, self.isbn, [self.queuePosition intValue], self.queueDescription, self.pickupAt,
		([self.readyForPickup boolValue]) ? @"YES" : @"NO", self.expiryDate];
}

@end