#import "DebugReporter.h"
#import "DataStore.h"
#import "Debug.h"

@implementation DebugReporter

- (void) presentDebugReporterForView: (UIViewController *) forView
{
	// No mail sending capability
	if ([MFMailComposeViewController canSendMail] == NO) return;

	// See if already displayed
	if (displayed) return;
	displayed = YES;
	
	view = [forView retain];
	
	UIAlertView *alert	= [[[UIAlertView alloc] init] autorelease];
	alert.title			= @"Send Debug Report to the Developer";
	alert.message		= @"Warning: the debug report may contain private information such as your name and address.";
	alert.delegate		= self;
	
	[alert addButtonWithTitle: @"Send..."];
	[alert addButtonWithTitle: @"Cancel"];
	[alert show];
}

- (void) alertView: (UIAlertView *) alertView didDismissWithButtonIndex: (NSInteger) buttonIndex
{
	// Only send the debug if the "Send" button was selected
	if (buttonIndex != 0)
	{
		displayed = NO;
		return;
	}
	
	// Send mail
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
	NSArray *libraryCards = [[DataStore sharedDataStore] selectLibraryCards];
	NSMutableArray *libraryCardNames = [NSMutableArray arrayWithCapacity: [libraryCards count]];
	for (LibraryCard *libraryCard in libraryCards)
	{
		[libraryCardNames addObject: libraryCard.libraryPropertyName];
	}
	
	[picker setSubject: [NSString stringWithFormat: @"Debug for %@", [libraryCardNames componentsJoinedByString: @", "]]];
	[picker setToRecipients: [NSArray arrayWithObject: @"Library Books Support <librarybooks+debug@haroldchu.id.au>"]];
	
	// Attach the debug file
    NSData *data = [NSData dataWithContentsOfFile: [Debug gzippedLogFilePath]];
	[picker addAttachmentData: data mimeType: @"application/x-gzip" fileName: @"Debug.html.gz"];
	
	[view presentModalViewController: picker animated: YES];
    [picker release];
}

- (void) mailComposeController: (MFMailComposeViewController*) controller
	didFinishWithResult: (MFMailComposeResult) result error: (NSError*) error 
{
	[view dismissModalViewControllerAnimated: YES];
	
    if (result == MFMailComposeResultSent)
    {
		UIAlertView *alert	= [[[UIAlertView alloc] init] autorelease];
		alert.title			= @"Debug Report Sent";
		alert.message		= @"Thanks for submitting a debug report.";
		
		[alert addButtonWithTitle: @"Close"];
		[alert show];
    }
	
	displayed = NO;
}

// =============================================================================
#pragma mark -
#pragma mark Singleton class handling

static DebugReporter *sharedDebugReporter = nil;

+ (DebugReporter *) sharedDebugReporter
{
    @synchronized(self)
	{
        if (sharedDebugReporter == nil)
		{
            sharedDebugReporter = [[DebugReporter alloc] init];
        }
    }
	
    return sharedDebugReporter;
}

+ (id) allocWithZone: (NSZone *) zone
{
    @synchronized(self)
	{
        if (sharedDebugReporter == nil)
		{
            return [super allocWithZone: zone];
        }
    }
    return sharedDebugReporter;
}

- (id) copyWithZone:(NSZone *)zone
{
    return self;
}

- (id) retain
{
    return self;
}

- (unsigned) retainCount
{
	// Denotes an object that cannot be released
    return UINT_MAX;
}

- (oneway void) release
{
    // Do nothing
}

- (id) autorelease
{
    return self;
}

@end
