#import "NSAttributedStringExtension.h"

@implementation NSAttributedString (NSAttributedStringExtension)

+ (NSAttributedString *) string: (NSString *) string attributes: (NSDictionary *) attributes
{
	return [[[NSAttributedString alloc] initWithString: string attributes: attributes] autorelease];
}

+ (NSAttributedString *) normalMenuString: (NSString *) string
{
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont menuFontOfSize: 14], NSFontAttributeName,
		nil
	];
	
	return [NSAttributedString string: string attributes: attributes];
}

+ (NSAttributedString *) normalPopUpMenuString: (NSString *) string
{
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont menuFontOfSize: 13], NSFontAttributeName,
		nil
	];
	
	return [NSAttributedString string: string attributes: attributes];
}

+ (NSAttributedString *) boldMenuString: (NSString *) string
{
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize: 14], NSFontAttributeName,
		nil
	];
	
	return [NSAttributedString string: string attributes: attributes];
}

+ (NSAttributedString *) smallDisabledMenuString: (NSString *) string
{
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont menuFontOfSize:	[NSFont smallSystemFontSize]],	NSFontAttributeName,
		[NSColor disabledControlTextColor],						NSForegroundColorAttributeName,
		nil
	];
	
	return [NSAttributedString string: string attributes: attributes];
}

+ (NSAttributedString *) tinyDisabledMenuString: (NSString *) string
{
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont menuFontOfSize:	[NSFont smallSystemFontSize] - 2],	NSFontAttributeName,
		[NSColor disabledControlTextColor],							NSForegroundColorAttributeName,
		nil
	];
	
	return [NSAttributedString string: string attributes: attributes];
}

+ (NSAttributedString *) tinyItalicDisabledMenuString: (NSString *) string
{
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont menuFontOfSize:	[NSFont smallSystemFontSize] - 2],	NSFontAttributeName,
		[NSColor disabledControlTextColor],							NSForegroundColorAttributeName,
		[NSNumber numberWithFloat:0.20],							NSObliquenessAttributeName,
		nil
	];
	
	return [NSAttributedString string: string attributes: attributes];
}

+ (NSAttributedString *) smallMenuString: (NSString *) string
{
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont menuFontOfSize:	[NSFont smallSystemFontSize]],	NSFontAttributeName,
		nil
	];
	
	return [NSAttributedString string: string attributes: attributes];
}

+ (NSAttributedString *) smallBoldMenuString: (NSString *) string
{
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]], NSFontAttributeName,
		nil
	];
	
	return [NSAttributedString string: string attributes: attributes];
}

+ (NSAttributedString *) paragraphBreak
{
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont menuFontOfSize:	5], NSFontAttributeName,
		nil
	];
	
	return [NSAttributedString string: @"\n " attributes: attributes];
}

+ (NSAttributedString *) htmlString: (NSString *) string
{
	NSData *data = [string dataUsingEncoding: NSUTF8StringEncoding];
	return [[[NSAttributedString alloc] initWithHTML: data documentAttributes: nil] autorelease];
}

+ (NSAttributedString *) tinyMenuStringAtNormalHeight: (NSString *) string
{
	const CGFloat height = 18;
	const CGFloat baseline = 4;

	NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	paragraphStyle.minimumLineHeight = height - baseline;
	paragraphStyle.maximumLineHeight = height - baseline;

	NSDictionary *attributes =
	@{
		NSFontAttributeName:			[NSFont menuFontOfSize: [NSFont smallSystemFontSize] - 2],
		NSParagraphStyleAttributeName:	paragraphStyle,
		NSBaselineOffsetAttributeName:	[NSNumber numberWithFloat: baseline]
	};
	
	return [NSAttributedString string: string attributes: attributes];
}

@end