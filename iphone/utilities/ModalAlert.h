#import <Foundation/Foundation.h>

@interface ModalAlert : NSObject <UIAlertViewDelegate>

@property(readonly) UIAlertView *alertView;

- (NSInteger) showModal;

@end