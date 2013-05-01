//
//  MenuViewController.m
//  bluetoothtest
//


#import "MenuViewController.h"
#import "TopViewController.h"

@interface MenuViewController () {
    NSArray *patterns;
}

@end

@implementation MenuViewController

- (void) viewDidLoad {
    patterns = [NSArray arrayWithObjects:@"ノーマル", @"ロング", @"煽り", nil];
    _pickerVIew.delegate = self;
    _pickerVIew.dataSource = self;
    
    TopViewController *superController = (TopViewController *)[self presentingViewController];
    NSLog(@"%d", superController.type);
    [_pickerVIew selectRow:superController.type inComponent:0 animated:YES];
}

- (void) viewWillDisappear:(BOOL)animated {
    
    TopViewController *superController = (TopViewController *)[self presentingViewController];
    superController.type = [_pickerVIew selectedRowInComponent:0];
}
//
//- (void) viewDidAppear:(BOOL)animated {
//    TopViewController *superController = (TopViewController *)[self presentingViewController];
//    NSLog(@"%d", superController.type);
//    [_pickerVIew selectRow:superController.type inComponent:0 animated:YES];
//}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 3;
}

- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [patterns objectAtIndex:row];
}

@end
