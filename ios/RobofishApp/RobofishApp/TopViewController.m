//
//  TopViewController.m
//  bluetoothtest


#import "TopViewController.h"

@interface TopViewController () {
    
    CBCentralManager *centralManager;
    CBPeripheral *targetPeripheral;
    CBService *targetService;
    CBCharacteristic *targetRx;
    CBCharacteristic *targetTx;
    BOOL isConnect;
    
    NSArray *temptPatterns;
    BOOL isAnimating;
}

typedef enum {
    StopAll = 1,
    StopPole,
    StopReel,
    ReelUp,
    ReelDown,
    Pole
} OutputToArduino;


@end

@implementation TopViewController

static NSString *UUIDCharacteristicsRx = @"e788d73b-e793-4d9e-a608-2f2bafc59a00";
static NSString *UUIDCharacteristicsTx = @"4585c102-7784-40b4-88e1-3cb5c4fd37a3";

- (void) viewDidLoad {
    _type = -1;
    isConnect = NO;
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];

    isAnimating = NO;
    temptPatterns = [NSArray arrayWithObjects:
                     @"ノーマル", @"長め", @"煽り", @"全開(危険!)",
                     nil];
    
    // アイコン初期設定
    [self setHiddenOfIcons:YES];
    [self setHiddenOfLabel:YES];
}

- (void) setHiddenOfIcons:(BOOL) isHidden {
    // アイコン初期設定
    _upBtn.hidden = isHidden;
    _downBtn.hidden = isHidden;
    _stopBtn.hidden = isHidden;
    _pullBtn.hidden = isHidden;
    _autoBtn.hidden = isHidden;
    _settingBtn.hidden = isHidden;
}

- (void) setHiddenOfLabel:(BOOL) isHidden {
    _upLbl.hidden = isHidden;
    _downLbl.hidden = isHidden;
    _stopLbl.hidden = isHidden;
    _pullLbl.hidden = isHidden;
    _autoLbl.hidden = isHidden;

}

- (void) viewDidAppear:(BOOL)animated {
    
    [UIView animateWithDuration:1.5 delay:0.3 options:UIViewAnimationOptionCurveEaseInOut animations:^{
    
        CGRect frame = _fish.frame;
        frame.origin.y = ([UIScreen mainScreen].bounds.size.height - frame.size.height) / 2.0;
        _fish.frame = frame;
        
    } completion:^(BOOL finished) {

    }];
}

-(void) blink {
    
    if (isConnect) {
        return;
    }
    
    __block TopViewController *_self = self;
    
    [UIView animateWithDuration:0.8 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        _bluetoothImg.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            _bluetoothImg.alpha = 1.0;
        } completion:^(BOOL finished) {
            [_self blink];
        }];
    }];
    
}

- (IBAction)fishDidPushed:(id)sender {
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGAffineTransform scale = CGAffineTransformMakeScale(1.2, 1.2);
        [_fish setTransform:scale];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGAffineTransform scale = CGAffineTransformMakeScale(1.0, 1.0);
            [_fish setTransform:scale];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.8 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                
                CGRect frame = _fish.frame;
                frame.origin.y = -200;
                _fish.frame = frame;
                
                frame = _bluetoothImg.frame;
                frame.origin.y = ([UIScreen mainScreen].bounds.size.height - frame.size.height) / 2.0;
                _bluetoothImg.frame = frame;
                
            } completion:^(BOOL finished) {
            }];
        }];
    }];

}

- (IBAction)bluetoothDidPush:(id)sender {
    
    if (isConnect) {
        if (targetPeripheral) {
            [centralManager cancelPeripheralConnection:targetPeripheral];
            centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        }
        isConnect = NO;
        
        __block TopViewController *_self = self;
        
        [UIView animateWithDuration:0.8 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            
            CGRect frame = _bluetoothImg.frame;
            frame.origin.y = ([UIScreen mainScreen].bounds.size.height - frame.size.height) / 2.0;
            _bluetoothImg.frame = frame;
            _bluetoothImg.alpha = 0.5;
            
        } completion:^(BOOL finished) {
        }];

        [_self scaleAnimationReverseWithButton:_upBtn delay:0];
        [_self scaleAnimationReverseWithButton:_downBtn delay:0];
        [_self scaleAnimationReverseWithButton:_stopBtn delay:0];
        [_self scaleAnimationReverseWithButton:_pullBtn delay:0];
        [_self scaleAnimationReverseWithButton:_autoBtn delay:0];
        [_self scaleAnimationReverseWithButton:_settingBtn delay:0];

        return;
    }
    __block TopViewController *_self = self;
    
    // 接続開始
    [self connect];
    [UIView animateWithDuration:0.8 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        CGRect frame = _bluetoothImg.frame;
        frame.origin.y = 20;
        _bluetoothImg.frame = frame;
        
    } completion:^(BOOL finished) {
        [_self blink];
    }];
}

#pragma mark - CBCentralManager Delegate

// BLE対応デバイスが検出されると呼び出される
- (void) centralManagerDidUpdateState:(CBCentralManager *)central {
    NSString *messtoshow;
    NSLog(@"--------------------------------");
    NSLog(@"[STEP 1] Result:centralManagerDidUpdateState:");
    NSLog(@"--------------------------------");
    switch (central.state) {
        case CBCentralManagerStateUnknown:
        {
            messtoshow = @"不明な状態です。";
            break;
        }
        case CBCentralManagerStateResetting:
        {
            messtoshow = @"接続を失いしました。";
            break;
        }
        case CBCentralManagerStateUnsupported:
        {
            messtoshow = @"このプラットフォームはBluetooth Low Energyをサポートしていません。";
            break;
        }
        case CBCentralManagerStateUnauthorized:
        {
            messtoshow = @"このアプリはBluetooth Low Energyの認証ができません。";
            break;
        }
        case CBCentralManagerStatePoweredOff:
        {
            messtoshow = @"Bluetoothが見つかりませんでした。";
            break;
        }
        case CBCentralManagerStatePoweredOn:
        {
            messtoshow = @"Bluetoothを発見、利用可能な状態です。";
            break;
        }
            
    }
    
    NSLog(@"%@", messtoshow);
}

// BLE対応サービスが検出されると呼び出される
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    
    NSLog(@"%@", peripheral.name);
    
    if ([[advertisementData objectForKey:@"kCBAdvDataLocalName"] rangeOfString:@"BLE-Shield A"].location != NSNotFound) {
        targetPeripheral = peripheral;
        targetPeripheral.delegate = self;
        [centralManager connectPeripheral:targetPeripheral options:nil];
        NSLog(@"Peripheralへの接続を試みます:%@",[advertisementData objectForKey:@"kCBAdvDataLocalName"]);
        
    } else if ([[advertisementData objectForKey:@"kCBAdvDataLocalName"] rangeOfString:@"BLE-Shield B"].location != NSNotFound) {
        targetPeripheral = peripheral;
        targetPeripheral.delegate = self;
        [centralManager connectPeripheral:targetPeripheral options:nil];
        NSLog(@"Peripheralへの接続を試みます:%@",[advertisementData objectForKey:@"kCBAdvDataLocalName"]);
        
    } else {
        NSLog(@"指定したPeripheralを発見できませんでした。");
        
    }
    
    
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"--------------------------------");
    NSLog(@"[STEP 3] Result:didConnectPeripherl");
    NSLog(@"--------------------------------");
    
    //    NSArray *services = nil;
    
    NSLog(@"%@", peripheral.UUID);
    
    NSLog(@"--------------------------------");
    NSLog(@"[STEP 4] discoverServices");
    NSLog(@"--------------------------------");
    [peripheral discoverServices:nil];
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"--------------------------------");
    NSLog(@"[STEP 4] Result:didDiscoverServices");
    NSLog(@"--------------------------------");
    
    if (error) {
        NSLog(@"fault to discovery services");
    } else {
        NSLog(@"--------------------------------");
        NSLog(@"[STEP 5] getAllCharacteristicsFromArduino");
        NSLog(@"--------------------------------");
        
        for (int i = 0; i < peripheral.services.count; i++) {
            
            CBService *service = [peripheral.services objectAtIndex:i];
            targetService = service;
            NSLog(@"ServiceのUUID %@", service.UUID);
            
            NSLog(@"--------------------------------");
            NSLog(@"[STEP 6]. discoverCharacteristics");
            NSLog(@"--------------------------------");
            
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
              error:(NSError *)error
{
    NSLog(@"--------------------------------");
    NSLog(@"[STEP 6] Result: didDiscoverCharacteristicsForService");
    NSLog(@"--------------------------------");
    
    if (error) {
        NSLog(@"didDiscoverCharacteristics error: %@", error);
        return;
    }
    
    if (service.characteristics.count == 0) {
        NSLog(@"didDiscoverCharacteristics no characteristics");
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
        
        
        NSLog(@"characteristic.UUID %@", characteristic.UUID);
        
        //characteristic.UUID.
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDCharacteristicsRx]]) {
            NSLog(@"Match RX");
            targetRx = characteristic;
            [targetPeripheral readValueForCharacteristic:targetRx];
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUIDCharacteristicsTx]]) {
            NSLog(@"Match TX");
            targetTx = characteristic;
            [targetPeripheral readValueForCharacteristic:targetTx];
        } else {
            NSLog(@"UnMatch");
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    
    NSLog(@"UUID : %@ was found", peripheral.UUID);
    
    UInt8 value[8];
    NSMutableData *data = [NSMutableData dataWithData:characteristic.value];
    [data increaseLengthBy:8];
    [data getBytes:&value length:sizeof(value)];
    NSMutableString *bleData = [NSMutableString string ];
    
    for (int i=0; i<8; i++) {
        [bleData  appendFormat:@"%02x", value[i]];
    }
    
    [bleData appendFormat:@"\n"];
    NSLog(@"[Read Value:] %@", bleData);
    
    isConnect = YES;
    _bluetoothImg.alpha = 1.0;
    
    [self showButtonAnimation];
}

- (void) scaleAnimationReverseWithButton:(UIButton *) button delay:(float) delay {
    [UIView animateWithDuration:0.2 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGAffineTransform scale = CGAffineTransformMakeScale(1.2, 1.2);
        [button setTransform:scale];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.7 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGAffineTransform scale = CGAffineTransformMakeScale(0, 0);
            [button setTransform:scale];
        } completion:^(BOOL finished) {
        }];
    }];
    
    if (button == _settingBtn) {
        [UIView animateWithDuration:0.5 animations:^{
            _upLbl.alpha =
            _downLbl.alpha =
            _stopLbl.alpha =
            _pullLbl.alpha =
            _autoLbl.alpha = 0;
            isAnimating = NO;
        }];

    }
}

- (void) scaleAnimationWithButton:(UIButton *) button delay:(float) delay {
    [UIView animateWithDuration:0.7 delay:delay options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGAffineTransform scale = CGAffineTransformMakeScale(1.2, 1.2);
        [button setTransform:scale];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGAffineTransform scale = CGAffineTransformMakeScale(1.0, 1.0);
            [button setTransform:scale];
        } completion:^(BOOL finished) {
            if (button == _settingBtn) {
                [self setHiddenOfLabel:NO];
                [UIView animateWithDuration:0.5 animations:^{
                    _upLbl.alpha =
                    _downLbl.alpha =
                    _stopLbl.alpha =
                    _pullLbl.alpha =
                    _autoLbl.alpha = 1;
                    isAnimating = NO;
                }];
            }
        }];
    }];
}

- (void) scaleToZero:(UIButton *) button {
    CGAffineTransform scale = CGAffineTransformMakeScale(0, 0);
    [button setTransform:scale];
}

- (void) showButtonAnimation {
    
    if (isAnimating) {
        return;
    }
    
    isAnimating = YES;
    [self setHiddenOfIcons:NO];
    
    [self scaleToZero:_upBtn];
    [self scaleToZero:_autoBtn];
    [self scaleToZero:_downBtn];
    [self scaleToZero:_stopBtn];
    [self scaleToZero:_pullBtn];
    [self scaleToZero:_settingBtn];
    
    [self scaleAnimationWithButton:_upBtn delay:0];
    [self scaleAnimationWithButton:_autoBtn delay:0.1];
    [self scaleAnimationWithButton:_downBtn delay:0.2];
    [self scaleAnimationWithButton:_stopBtn delay:0.3];
    [self scaleAnimationWithButton:_pullBtn delay:0.4];
    [self scaleAnimationWithButton:_settingBtn delay:0.7];
}

#pragma mark - Private Methods

- (void) setType:(int)type {
    switch (type) {
        case 0:
            [self sendCharacterToArduino:"x"];
            break;
        case 1:
            [self sendCharacterToArduino:"y"];
            break;
        case 2:
            [self sendCharacterToArduino:"z"];
            break;
        default:
            break;
    }
    
    _type = type;
}

- (void) sendCharacterToArduino: (const char *) character {
    
    NSData * data=[NSData dataWithBytes:character length:strlen(character)];
    
    [targetPeripheral writeValue:data forCharacteristic:targetRx type:CBCharacteristicWriteWithResponse];
}

- (void) connect {
    if (isConnect) {
        if (targetPeripheral) {
            [centralManager cancelPeripheralConnection:targetPeripheral];
            centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        }
        isConnect = NO;
    } else {
        
        NSArray *services = [NSArray arrayWithObjects:nil, nil];
        // イベントを重複させない
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                            forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [centralManager scanForPeripheralsWithServices:services options:options];

    }
}

// 巻きだし
- (IBAction)stopReelDown:(id)sender {
    [self sendCharacterToArduino:"s"];
}

- (IBAction)reelDown:(id)sender {
    [self sendCharacterToArduino:"o"];
}

// 巻き取り
- (IBAction)reelUp:(id)sender {
    [self sendCharacterToArduino:"i"];
}

- (IBAction)stopReelUp:(id)sender {
    [self sendCharacterToArduino:"s"];
}

// 全部停止
- (IBAction)stopAll:(id)sender {
    [self sendCharacterToArduino:"w"];
}

// 引く
- (IBAction)pull:(id)sender {
    [self sendCharacterToArduino:"b"]; 
}

// 誘い
- (IBAction)pole:(id)sender {
    [self sendCharacterToArduino:"p"];
}

@end
