//
//  MenuViewController.h
//  bluetoothtest
//
//

#import <UIKit/UIKit.h>

@interface MenuViewController : UIViewController<UIPickerViewDelegate, UIPickerViewDataSource>
@property (weak, nonatomic) IBOutlet UIPickerView *pickerVIew;

@end
