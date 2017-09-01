//
//  NearbyPeripheralsViewController.m
//  ISS
//
//  Created by Anshuman Dahale on 4/13/17.
//  Copyright © 2017 Digvijay Joshi. All rights reserved.
//

#import "NearbyPeripheralsViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BluetoothManager.h"
#import "ApplicationManager.h"

@interface NearbyPeripheralsViewController ()

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *periferals;

@property (nonatomic, strong) BluetoothManager *bluetoothManager;
@property (nonatomic, strong) CBPeripheral *selectedPeripheral;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityView;
@property (nonatomic, strong) IBOutlet UILabel *messageLabel;

@end

@implementation NearbyPeripheralsViewController

#pragma mark - Navigation

- (void) popToRootView {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Table View Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [_periferals count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellIdentifier"];
    CBPeripheral *peripheral = [_periferals objectAtIndex:indexPath.row];
    cell.textLabel.text = peripheral.name;
    
    if(peripheral == _selectedPeripheral) {
        
        switch (_selectedPeripheral.state) {
            case CBPeripheralStateConnected:
                cell.accessoryView = nil;
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
                [self performSelector:@selector(popToRootView) withObject:nil afterDelay:0.3];
                break;
            case CBPeripheralStateConnecting:
                {
                    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    spinner.frame = CGRectMake(0, 0, 30, 30);
                    [spinner startAnimating];
                    spinner.hidesWhenStopped = YES;
                    cell.accessoryView = spinner;
                }
                break;
            default:
                break;
        }
    }
    else {
//        cell.accessoryView = nil;
//        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

#pragma mark - Table View Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    _selectedPeripheral = [_periferals objectAtIndex:indexPath.row];
    [_tableView reloadData];
    [_bluetoothManager connectToPeripheral:_selectedPeripheral WithConnectionBlock:^(NSError *error, NSString *peripheralName) {
        [ApplicationManager sharedInstance].deviceName = peripheralName;
        [_tableView reloadData];
    }];
}


#pragma mark - View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _tableView.hidden = YES;
    [_activityView startAnimating];
    _activityView.hidesWhenStopped = YES;
    _messageLabel.text = @"Scanning...";
    _bluetoothManager = [BluetoothManager sharedInstance];
    [_bluetoothManager getPeripheralListWithComplitionBlock:^(NSError *error, NSArray *periferals) {
        
        if(!error) {
            _periferals = [[NSArray alloc] initWithArray:periferals];
            [_activityView stopAnimating];
            _messageLabel.text = @"";
            _tableView.hidden = NO;
            [_tableView reloadData];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
