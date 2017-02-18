#import <Cocoa/Cocoa.h>

@interface ComboSecureTextField : NSTabView
{
	NSTextField			*textField;
	NSSecureTextField	*secureTextField;
}

@property(nonatomic, retain)	NSString	*text;
@property(nonatomic)			BOOL		secureTextEntry;
@property(nonatomic, retain)	NSString	*placeholder;

@end