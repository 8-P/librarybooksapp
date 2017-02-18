// =============================================================================
//
// Table view controller for adding or editing library card settings.
//
// Special handling:
//		* Special keyboard handling of the "Done" button.
//		* Enabling the save button when compulsory fields are filled in.
//		* Puts "ABC" button on numeric keypad.  There is special handling
//		  for OS 3.2+.
//
// Not here:
//		* The slide up animation.  This is done by the calling method.
//
// =============================================================================

#import "LibraryCardViewController.h"
#import "EditableTableViewCell.h"
#import "DataStore.h"
#import "LibraryCard.h"
#import "LibrariesViewController.h"
#import "UIColorFactory.h"
#import "SingleLibrary.h"

// Constants -------------------------------------------------------------------

#define kTagLibrary				0
#define kTagAuthentication1		1
#define kTagAuthentication2		2
#define kTagAuthentication3		3
#define kTagDescription			4
#define kTagEnabled				5

// -----------------------------------------------------------------------------

@implementation LibraryCardViewController

@dynamic libraryCard;

- (void) dealloc
{
	[saveButton release];
	[cancelButton release];
	[libraryCard release];
	[opac release];
	[keyboardABCButton release];
	[keyboardTextField release];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	
    [super dealloc];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationController.navigationBar.tintColor = [UIColorFactory themeColor];
	
	// Set up the save and cancel buttons
	saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemSave target: self action: @selector(save:)];
	self.navigationItem.rightBarButtonItem = saveButton;
	cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(cancel:)];
	self.navigationItem.leftBarButtonItem = cancelButton;
	
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	NSString *notificationName = ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2)
		? UIKeyboardDidShowNotification: UIKeyboardWillShowNotification;
	[notificationCenter addObserver: self selector: @selector(keyboardWillShow:) name: notificationName object: nil];
	[notificationCenter addObserver: self selector: @selector(keyboardWillHide:) name: UIKeyboardWillHideNotification object: nil];
	
	SingleLibrary *singleLibrary = [SingleLibrary sharedSingleLibrary];
	singleLibraryCardMode = singleLibrary.enabled;
	if (singleLibraryCardMode && libraryCard == nil)
	{
		LibraryCard *singleLibraryCard			= [LibraryCard libraryCard];
		singleLibraryCard.name					= singleLibrary.name;
		singleLibraryCard.libraryPropertyName	= singleLibrary.identifier;
		singleLibraryCard.ordering				= [NSNumber numberWithInt: [[DataStore sharedDataStore] maxLibraryCardOrdering] + 1];
		self.libraryCard						= singleLibraryCard;
	
		// Make sure we are in "Add mode"
		editMode								= AddLibraryCard;
	}
}

// -----------------------------------------------------------------------------
//
// Remember the edit mode when libraryCard variable is set.
//
// -----------------------------------------------------------------------------
- (void) setLibraryCard: (LibraryCard *) _libraryCard
{
	libraryCard = [_libraryCard retain];
	if (libraryCard)
	{
		// Editing an existing account
		editMode = EditLibraryCard;
		self.navigationItem.title = libraryCard.name;
	}
}

- (void) viewDidAppear: (BOOL) animated
{
	[super viewDidAppear: animated];
	
	if (libraryCard == nil)
	{
		// Creating a new account.  Note that we can only create a new account
		// in viewDidAppear: and not earlier (e.g. viewDidLoad:) because it will
		// cause a blank row to appear while this view slides into place
		editMode						= AddLibraryCard;
		libraryCard						= [[LibraryCard libraryCard] retain];
		libraryCard.libraryPropertyName = @"";
		libraryCard.ordering			= [NSNumber numberWithInt: [[DataStore sharedDataStore] maxLibraryCardOrdering] + 1];
		self.navigationItem.title		= @"Add Library Card";
	}
	
	[self updateOPAC];
	[self updateSaveEnabled];
}

// -----------------------------------------------------------------------------
//
// The table view needs to be reloaded after the a library is selected. So
// after the LibrariesViewController is closed this viewWillAppear: method
// will fire.
//
// -----------------------------------------------------------------------------
- (void) viewWillAppear: (BOOL) animated
{
	[super viewWillAppear: animated];
	
	[self updateOPAC];
	[self.tableView reloadData];

	// Update the description once a library has been selected
	[self autoFillDescription];
	
	// Make sure the save button is enabled/disabed correctly
	[self updateSaveEnabled];
}

- (void) cancel: (id) sender
{
	[[DataStore sharedDataStore] rollback];
	[self dismissModalViewControllerAnimated: YES];
}

- (void) save: (id) sender
{
	// We have to ensure unique library card names so that the section names
	// in the table view are displayed correctly
	libraryCard.name = [self unqiueLibraryCardNameFrom: libraryCard.name];

	[[DataStore sharedDataStore] save];
	[self dismissModalViewControllerAnimated: YES];
}

- (void) updateSaveEnabled
{
	saveButton.enabled =
		   opac
		&& [libraryCard.libraryPropertyName length] > 0
		&& ((1 <= opac.authenticationCount && opac.authentication1Required) ? [libraryCard.authentication1 length] > 0 : YES)
		&& ((2 <= opac.authenticationCount && opac.authentication2Required) ? [libraryCard.authentication2 length] > 0 : YES)
		&& ((3 <= opac.authenticationCount && opac.authentication3Required) ? [libraryCard.authentication3 length] > 0 : YES)
		&& [libraryCard.name length] > 0;
}

- (void) updateOPAC
{
	if ([libraryCard.libraryPropertyName length] > 0)
	{
		LibraryProperties *libraryProperties = [LibraryProperties libraryProperties];
		NSMutableDictionary *properties = [libraryProperties libraryPropertiesForIdentifier: libraryCard.libraryPropertyName];
		
		[opac release];
		opac = [[OPAC opacForProperties: properties] retain];
	}
}

// =============================================================================
#pragma mark -
#pragma mark Table view methods

- (NSInteger) numberOfSectionsInTableView: (UITableView *) tableView
{
    return 1;
}

- (NSString *) tableView: (UITableView *) tableView titleForFooterInSection: (NSInteger) section
{
	if ([libraryCard.libraryPropertyName length] > 0)
	{
		LibraryProperties *libraryProperties = [LibraryProperties libraryProperties];
		NSDictionary *properties = [libraryProperties libraryPropertiesForIdentifier: libraryCard.libraryPropertyName];
		
		return [properties objectForKey: @"Note"];
	}
	
	return nil;
}

// -----------------------------------------------------------------------------
//
// Customize the number of rows in the table view.
//
// Notes:
//		* When editing an existing library we add an extra row for the
//		  enable/disable control
//		* Need to check libraryCard && editMode because the editMode is not
//		  set correctly at startup
//
// -----------------------------------------------------------------------------
- (NSInteger) tableView: (UITableView *) tableView numberOfRowsInSection: (NSInteger) section
{
	if (singleLibraryCardMode)
	{
		return 1 + opac.authenticationCount
				 + ((libraryCard && editMode == EditLibraryCard) ? 1 : 0);
	}
	else
	{
		return 2 + opac.authenticationCount
				 + ((libraryCard && editMode == EditLibraryCard) ? 1 : 0);
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *) tableView: (UITableView *) tableView cellForRowAtIndexPath: (NSIndexPath *) indexPath
{
    EditableTableViewCell *cell = (EditableTableViewCell *) [tableView dequeueReusableCellWithIdentifier: @"EditableCell"];
    if (cell == nil)
	{
        cell = [[[EditableTableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: @"EditableCell"] autorelease];
		[cell.valueField setDelegate: self];
		[cell.valueField addTarget: self action: @selector(textFieldDidChange:) forControlEvents: UIControlEventEditingChanged];
    }

	int indexPathRow = indexPath.row;
	if (singleLibraryCardMode) indexPathRow++;

	if (indexPathRow == 0)
	{
		cell.textLabel.text						= @"Library";
		cell.accessoryType						= UITableViewCellAccessoryDisclosureIndicator;
		cell.valueField.placeholder				= @"Select Library";
		cell.valueField.enabled					= NO;
		cell.valueField.tag						= kTagLibrary;
		cell.valueField.text					= opac.name;
		cell.selectionStyle						= UITableViewCellSelectionStyleBlue;
		cell.valueField.secureTextEntry			= NO;
	}
	else if (1 <= indexPathRow && indexPathRow <= opac.authenticationCount)
	{
		cell.valueField.autocapitalizationType	= UITextAutocapitalizationTypeNone;
		cell.valueField.autocorrectionType		= UITextAutocorrectionTypeNo;
		cell.valueField.clearButtonMode			= UITextFieldViewModeWhileEditing;
		
		switch (indexPathRow)
		{
			case 1:
				cell.textLabel.text				= opac.authentication1Title;
				cell.valueField.text			= libraryCard.authentication1;
				cell.valueField.secureTextEntry	= opac.authentication1IsSecure;
				cell.valueField.tag				= kTagAuthentication1;
				cell.valueField.placeholder		= (opac.authentication1Required) ? @"Required" : @"";
				cell.valueField.keyboardType	= (opac.authentication1IsNumber) ? UIKeyboardTypeNumberPad : UIKeyboardTypeDefault;
				break;
			case 2:
				cell.textLabel.text				= opac.authentication2Title;
				cell.valueField.text			= libraryCard.authentication2;
				cell.valueField.secureTextEntry	= opac.authentication2IsSecure;
				cell.valueField.tag				= kTagAuthentication2;
				cell.valueField.placeholder		= (opac.authentication2Required) ? @"Required" : @"";
				cell.valueField.keyboardType	= (opac.authentication2IsNumber) ? UIKeyboardTypeNumberPad : UIKeyboardTypeDefault;
				break;
			case 3:
				cell.textLabel.text				= opac.authentication3Title;
				cell.valueField.text			= libraryCard.authentication3;
				cell.valueField.secureTextEntry	= opac.authentication3IsSecure;
				cell.valueField.tag				= kTagAuthentication3;
				cell.valueField.placeholder		= (opac.authentication3Required) ? @"Required" : @"";
				cell.valueField.keyboardType	= (opac.authentication3IsNumber) ? UIKeyboardTypeNumberPad : UIKeyboardTypeDefault;
				break;
		}
	}
	else if (indexPathRow == opac.authenticationCount + 1)
	{
		cell.textLabel.text						= @"Display Name";
		cell.valueField.placeholder				= @"Lucy's Library Card";
		cell.valueField.autocapitalizationType	= UITextAutocapitalizationTypeWords;
		cell.valueField.autocorrectionType		= UITextAutocorrectionTypeDefault;
		cell.valueField.tag						= kTagDescription;
		cell.valueField.text					= libraryCard.name;
		cell.valueField.clearButtonMode			= UITextFieldViewModeWhileEditing;
		cell.valueField.secureTextEntry			= NO;
		cell.valueField.keyboardType			= UIKeyboardTypeDefault;
	}
	else
	{
		// Recycle a different cell for the enable switch
		cell = (EditableTableViewCell *) [tableView dequeueReusableCellWithIdentifier: @"SwitchCell"];
		if (cell == nil)
		{
			cell					= [[[EditableTableViewCell alloc] initWithFrame: CGRectZero reuseIdentifier: @"SwitchCell"] autorelease];
			UISwitch *view			= [[[UISwitch alloc] initWithFrame: CGRectZero] autorelease];
			cell.accessoryView		= view;
			cell.valueField.enabled	= NO;
			[view addTarget: self action: @selector(switchChanged:) forControlEvents: UIControlEventValueChanged];
		}
	
		cell.textLabel.text						= @"Enabled";
		((UISwitch *) cell.accessoryView).on	= [libraryCard.enabled boolValue];
		cell.accessoryView.tag					= kTagEnabled;
	}

    return cell;
}

// -----------------------------------------------------------------------------
//
// Handle cell selection.
//
// -----------------------------------------------------------------------------
- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
	int indexPathRow = indexPath.row;
	if (singleLibraryCardMode) indexPathRow++;
	
	// The first item is the library selector.  All other items are text edit
	// rows
	if (indexPathRow == 0)
	{
		// Display the library selector
		LibrariesViewController *viewController = [[LibrariesViewController alloc] initWithStyle: UITableViewStyleGrouped];
		viewController.libraryCard = libraryCard;
		[self.navigationController pushViewController: viewController animated: YES];
		[viewController release];
	}
	else
	{
		// Put focus on the text field
		EditableTableViewCell *cell	= (EditableTableViewCell *) [self.tableView cellForRowAtIndexPath: indexPath];
		[cell.valueField becomeFirstResponder];
	}
}

// =============================================================================
#pragma mark -
#pragma mark Text field delegates

- (void) textFieldDidBeginEditing: (UITextField *) textField
{
	// Remember what text field we are editing so we can handle the switching
	// of keyboards
	[keyboardTextField release];
	keyboardTextField = [textField retain];
	
	keyboardABCButton.hidden = (keyboardTextField.keyboardType != UIKeyboardTypeNumberPad);
}

// -----------------------------------------------------------------------------
//
// Add the ABC button.
//
//		* The button needs to be added to all keyboards regardless of type.
//		  Because:
//				* The function only gets call once.
//				* The keyboard is recycled for the other fields.
//
// -----------------------------------------------------------------------------
- (void) keyboardWillShow: (NSNotification *) notification
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		keyboardABCButton = [[UIButton alloc] initWithFrame: CGRectZero];
		return;
	}

	// Create the "ABC" button overlay
	if (keyboardABCButton == nil)
	{
		keyboardABCButton = [[UIButton alloc] initWithFrame: CGRectMake(0, 165, 105, 53)];
		
		[keyboardABCButton setTitle: @"ABC" forState: UIControlStateNormal];
		
		// Make the title look like the other keyboard labels
		keyboardABCButton.titleLabel.font =	[UIFont boldSystemFontOfSize: 22];
		keyboardABCButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
		[keyboardABCButton setTitleShadowColor: [UIColor colorWithWhite: 1 alpha: 0.6] forState: UIControlStateNormal];
		[keyboardABCButton setTitleColor: [UIColor colorWithRed: 0.302 green: 0.329 blue: 0.384 alpha: 1] forState: UIControlStateNormal];
		
		[keyboardABCButton addTarget: self action: @selector(abcButtonPressed:) forControlEvents: UIControlEventTouchUpInside];
	}
	
	// Only display "ABC" on number pad keyboards
	keyboardABCButton.hidden = (keyboardTextField.keyboardType != UIKeyboardTypeNumberPad);

	// Find the keyboard window and draw the ABC button
	NSArray *windows = [[UIApplication sharedApplication] windows];
	if ([windows count] < 2) return;
	
	NSString *descriptionPrefix = ([[[UIDevice currentDevice] systemVersion] floatValue] >= 3.2)
		? @"<UIPeripheralHost" : @"<UIKeyboard";
	
	UIWindow* window = [windows objectAtIndex: 1];
	UIView* keyboard;
	for (int i = 0; i < [window.subviews count]; i++)
	{
		keyboard = [window.subviews objectAtIndex: i];
		if ([[keyboard description] hasPrefix: descriptionPrefix] == YES)
		{
			if ([keyboardABCButton superview] != keyboard)
			{
				[keyboard addSubview: keyboardABCButton];
			}
		}
	}
}

- (void) abcButtonPressed: (id) sender
{
	keyboardTextField.keyboardType = UIKeyboardTypeDefault;
	keyboardABCButton.hidden = YES;
	[keyboardTextField resignFirstResponder];
	[keyboardTextField becomeFirstResponder];
}

- (void) keyboardWillHide: (NSNotification *) notification
{
	keyboardABCButton.hidden = YES;
}

- (void) textFieldDidEndEditing: (UITextField *) textField
{
	switch (textField.tag)
	{
		case kTagAuthentication1: libraryCard.authentication1 = textField.text; break;
		case kTagAuthentication2: libraryCard.authentication2 = textField.text; break;
		case kTagAuthentication3: libraryCard.authentication3 = textField.text; break;
		case kTagDescription:
		{
			libraryCard.name = textField.text;
			
			// Update the title if we are editing a library card.  Don't modify
			// it if we a adding a new one because changing the "Add Library Card"
			// title looks confusing
			if (editMode == EditLibraryCard)
			{
				self.navigationItem.title = textField.text;
			}
			
			break;
		}
	}
	
	[self updateSaveEnabled];
}

- (void) switchChanged: (UISwitch *) switchControl
{
	switch (switchControl.tag)
	{
		case kTagEnabled: libraryCard.enabled = [NSNumber numberWithBool: switchControl.on]; break;
	}
}

// -----------------------------------------------------------------------------
//
// Choose a unique description.
// 
// -----------------------------------------------------------------------------
- (void) autoFillDescription
{
	if ([libraryCard.name length] == 0 && opac)
	{
		libraryCard.name = [self unqiueLibraryCardNameFrom: opac.name];
	}
}

- (NSString *) unqiueLibraryCardNameFrom: (NSString *) baseName
{
	DataStore *dataStore	= [DataStore sharedDataStore];
	NSString *unqiueName	= baseName;
	int i					= 2;
	while ([[dataStore libraryCardsNamed: unqiueName ignoringLibraryCard: libraryCard] count] > 1)
	{
		unqiueName = [NSString stringWithFormat: @"%@ (%d)", baseName, i];
		i++;
	}
	
	return unqiueName;
}

- (void) textFieldDidChange: (id) sender
{
	[self textFieldDidEndEditing: sender];
}

// -----------------------------------------------------------------------------
//
// Put keyboard focus on the next text field when the "Done" button is selected.
//
// -----------------------------------------------------------------------------
- (BOOL) textFieldShouldReturn: (UITextField *) textField
{
	UITableViewCell *cell	= (UITableViewCell *) [[textField superview] superview];
	NSIndexPath *indexPath	= [self.tableView indexPathForCell: cell];
	
	// Figure out the next row
	NSUInteger nextRow = indexPath.row + 1;
	if (nextRow < [self.tableView numberOfRowsInSection: 0])
	{
		NSIndexPath *nextIndexPath		= [NSIndexPath indexPathForRow: nextRow inSection: 0];
		EditableTableViewCell *nextCell	= (EditableTableViewCell *) [self.tableView cellForRowAtIndexPath: nextIndexPath];
		
		[nextCell.valueField becomeFirstResponder];
	}
	
	return YES;
}

- (BOOL) shouldAutorotateToInterfaceOrientation: (UIInterfaceOrientation) interfaceOrientation
{
	return YES;
}

@end