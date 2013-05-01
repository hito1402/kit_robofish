//
//  ViewController.h
//  bluetoothtest
//


#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController<CBCentralManagerDelegate, CBPeripheralDelegate,
UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *stateLbl;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
