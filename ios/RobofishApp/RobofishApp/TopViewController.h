//
//  TopViewController.h
//  bluetoothtest
//


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface TopViewController : UIViewController<CBCentralManagerDelegate, CBPeripheralDelegate,
UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) int type;
@property (weak, nonatomic) IBOutlet UIButton *fish;
@property (weak, nonatomic) IBOutlet UIButton *bluetoothImg;
@property (weak, nonatomic) IBOutlet UIButton *upBtn;
@property (weak, nonatomic) IBOutlet UIButton *downBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;
@property (weak, nonatomic) IBOutlet UIButton *pullBtn;
@property (weak, nonatomic) IBOutlet UIButton *autoBtn;
@property (weak, nonatomic) IBOutlet UIButton *settingBtn;
@property (weak, nonatomic) IBOutlet UILabel *upLbl;
@property (weak, nonatomic) IBOutlet UILabel *downLbl;
@property (weak, nonatomic) IBOutlet UILabel *stopLbl;
@property (weak, nonatomic) IBOutlet UILabel *pullLbl;
@property (weak, nonatomic) IBOutlet UILabel *autoLbl;

@end
