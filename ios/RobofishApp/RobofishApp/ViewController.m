//
//  ViewController.m
//  bluetoothtest
//


#import "ViewController.h"

@interface ViewController () {
    CBCentralManager *centralManager;
    CBPeripheral *targetPeripheral;
    CBService *targetService;
    CBCharacteristic *targetRx;
    CBCharacteristic *targetTx;
    BOOL isConnect;
    
    NSArray *temptPatterns;
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

@implementation ViewController

static NSString *UUIDCharacteristicsRx = @"e788d73b-e793-4d9e-a608-2f2bafc59a00";
static NSString *UUIDCharacteristicsTx = @"4585c102-7784-40b4-88e1-3cb5c4fd37a3";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    isConnect = NO;
    
    temptPatterns = [NSArray arrayWithObjects:
                     @"ノーマル", @"長め", @"煽り", @"全開(危険!)",
                     nil];
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
        isConnect = YES;
        
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
    
    _stateLbl.text = @"Connected";
    
}

#pragma mark - UITableView Delegate
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return temptPatterns.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [temptPatterns objectAtIndex:indexPath.row];
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        case 0:
            [self sendCharacterToArduino:"x"];
            break;
        case 1:
            [self sendCharacterToArduino:"y"];
            break;
        case 2:
            [self sendCharacterToArduino:"z"];
            break;
        case 3:
            [self sendCharacterToArduino:"f"];
            break;
        default:
            break;
    }
    
}

#pragma mark -Private Methods

- (void) sendCharacterToArduino: (const char *) character {
    
    NSData * data=[NSData dataWithBytes:character length:strlen(character)];
    
    [targetPeripheral writeValue:data forCharacteristic:targetRx type:CBCharacteristicWriteWithResponse];
    
}

- (IBAction)connectDidPushed:(id)sender {
    
    if (isConnect) {
        _stateLbl.text = @"No Connection";
        if (targetPeripheral) {
            [centralManager cancelPeripheralConnection:targetPeripheral];
            centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        }
        isConnect = NO;
        [(UIButton *) sender setTitle:@"connect" forState:UIControlStateNormal];
    } else {
        _stateLbl.text = @"Connecting...";
        
        NSArray *services = [NSArray arrayWithObjects:nil, nil];
        // イベントを重複させない
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                            forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [centralManager scanForPeripheralsWithServices:services options:options];
        
        isConnect = YES;
        
        [(UIButton *) sender setTitle:@"dis connect" forState:UIControlStateNormal];
    }
    
}

- (IBAction)upDidPushed:(id)sender {
    [self sendCharacterToArduino:"i"];
}

- (IBAction)stopReelUp:(id)sender {
    [self sendCharacterToArduino:"s"];
}

- (IBAction)downDidPushed:(id)sender {
    [self sendCharacterToArduino:"o"];
}
- (IBAction)stopReelDown:(id)sender {
    [self sendCharacterToArduino:"s"];
}

- (IBAction)stopDidPushed:(id)sender {
    [self sendCharacterToArduino:"w"];
}

- (IBAction)stopReel:(id)sender {
    [self sendCharacterToArduino:"s"];
}

- (IBAction)pole:(id)sender {
    [self sendCharacterToArduino:"p"];
}

- (IBAction)stopPole:(id)sender {
    [self sendCharacterToArduino:"a"];
}

- (IBAction)pull:(id)sender {
    [self sendCharacterToArduino:"b"];
}

- (void)viewDidUnload {
    [self setStateLbl:nil];
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
