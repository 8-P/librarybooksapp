#import <UIKit/UIKit.h>
#import "LibraryCard.h"
#import "OPAC.h"

typedef enum {EditLibraryCard, AddLibraryCard} LibraryCardEditMode;

@interface LibraryCardViewController : UITableViewController <UITextFieldDelegate>
{
	UIBarButtonItem			*saveButton;
	UIBarButtonItem			*cancelButton;
	LibraryCard				*libraryCard;
	LibraryCardEditMode		editMode;
	BOOL					singleLibraryCardMode;
	OPAC <OPAC>				*opac;
	
	UITextField				*keyboardTextField;
	UIButton				*keyboardABCButton;
}

@property (nonatomic, retain) LibraryCard *libraryCard;

- (void) updateSaveEnabled;
- (void) updateOPAC;
- (void) autoFillDescription;
- (NSString *) unqiueLibraryCardNameFrom: (NSString *) baseName;

@end