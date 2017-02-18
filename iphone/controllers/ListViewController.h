#import <UIKit/UIKit.h>

@interface ListViewController : UITableViewController
{
	NSDictionary	*propertyList;
	
	NSString		*key;
	NSArray			*titles;
	NSArray			*values;
	NSUserDefaults	*defaults;
}

@property(retain) NSDictionary	*propertyList;

@end