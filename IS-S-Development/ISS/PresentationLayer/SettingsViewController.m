//
//  SettingsViewController.m
//  ISS
//
//  Created by Anshuman Dahale on 2/24/17.
//  Copyright © 2017 Digvijay Joshi. All rights reserved.
//

#import "SettingsViewController.h"
#import "ApplicationManager.h"
#import "Enums.h"
#import "Constants.h"
#import "AESKeyViewController.h"
#import "Utility.h"
#import "SwitchControlTableViewCell.h"


@interface SettingsViewController () <SwitchControlTableViewCellProtocol>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic) Encryption_Key_Type keyType;

@end

@implementation SettingsViewController


#pragma mark - SwitchControlTableViewCellProtocol
- (void) switchValueChangedTo:(BOOL)value forIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.row) {
        
        //Dark Mode Cell
        case 0:
            {
                [[ApplicationManager sharedInstance] setIsDarkMode:value];
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSettingsChanged object:nil];
            }
            break;
        
        //AES Encryption cell
        case 1:
            {
                [[ApplicationManager sharedInstance] setShouldEncrypt:value];
                [_tableView reloadData];
            }
            break;
        default:
            break;
    }
}

#pragma mark - Table View Data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 9;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //For inverting color cell
    if(indexPath.row == 0) {
        
        SwitchControlTableViewCell *cell = (SwitchControlTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"invertColorCellIdentifier"];
        [cell.switchControl setOn:[ApplicationManager sharedInstance].isDarkMode];
        cell.cellType = Switch_Cell_Type_InvertColors;
        cell.indexPath = indexPath;
        cell.delegate = self;
        return cell;
    }
    
    //For Enabling AES Encryption cell
    if(indexPath.row == 1) {
        
        SwitchControlTableViewCell *cell = (SwitchControlTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"aesEncryptionCellIdentifier"];
        [cell.switchControl setOn:[ApplicationManager sharedInstance].shouldEncrypt];
        cell.cellType = Switch_Cell_Type_AES_Encryption;
        cell.indexPath = indexPath;
        cell.delegate = self;
        return cell;
    }
    
    //For other normal cells
    if(indexPath.row == 2) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"normalCellIdentifier"];
        return cell;
    }
    
    //For other AES Key cell
    if(indexPath.row == 3) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"aesKeyCellIdentifier"];
        cell.userInteractionEnabled = [ApplicationManager sharedInstance].shouldEncrypt;
        cell.contentView.alpha = [ApplicationManager sharedInstance].shouldEncrypt ? 1.0 : 0.2;
        return cell;
    }
    
    //iv Key
    if(indexPath.row == 4) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ivKeyCellIdentifier"];
        cell.userInteractionEnabled = [ApplicationManager sharedInstance].shouldEncrypt;
        cell.contentView.alpha = [ApplicationManager sharedInstance].shouldEncrypt ? 1.0 : 0.2;
        return cell;
    }
    
    
    //Passcode
    if(indexPath.row == 5) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"scanCellIdentifier"];
        cell.textLabel.text = @"Passcode";
        return cell;
    }
    
    
    //Device List
    if(indexPath.row == 6) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"scanCellIdentifier"];
        cell.textLabel.text = @"Nearby BLE peripherals";
        return cell;
    }
    
    
    //Device name
    if(indexPath.row == 7) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"deviceNameCellIdentifier"];
        NSString *deviceName = [ApplicationManager sharedInstance].deviceName;
        if(deviceName.length == 0) {
            
            cell.textLabel.text = @"Not connected to any BLE device";
            cell.textLabel.textColor = kLightRedColor;
        }
        else {
            cell.textLabel.text = [NSString stringWithFormat:@"Connected to: %@",deviceName];
            cell.textLabel.textColor = kDarkGreenColor;
        }
        return cell;
    }
    
    //Build version
    if(indexPath.row == 8) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"buildVersionCellIdentifier"];
        cell.textLabel.text = [Utility getBuildVersion];
        return cell;
    }
    return nil;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    NSLog(@"Clicked at index: %ld", (long)indexPath.row);
    if(indexPath.row == 2) {
        
        [self performSegueWithIdentifier:@"segueToRadioSettings" sender:self];
    }
    //AES Key
    else if(indexPath.row == 3) {
        
        _keyType = Encryption_Key_Type_AES;
        [self performSegueWithIdentifier:@"segueToEncryptionKeyViewController" sender:self];
    }
    //IV Key
    else if (indexPath.row == 4) {
        
        _keyType = Encryption_Key_Type_IV;
        [self performSegueWithIdentifier:@"segueToEncryptionKeyViewController" sender:self];
    }
    
    //Passcode
    else if (indexPath.row == 5) {
        
        _keyType = Encryption_Key_Type_PassCode;
        [self performSegueWithIdentifier:@"segueToEncryptionKeyViewController" sender:self];
    }
    
    //Scann for BLE
    else if (indexPath.row == 6) {
        
        [self performSegueWithIdentifier:@"segueToPeripheralListViewController" sender:self];
    }
}


- (IBAction)doneButton_TouchUpInside:(id)sender {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSettingsViewClosed object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)invertKeysSwitch_ValueChanged:(id)sender {
//    NSLog(@"Invert key colors");
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.destinationViewController isKindOfClass:[AESKeyViewController class]]) {
        
        AESKeyViewController *viewController = segue.destinationViewController;
        viewController.keyType = _keyType;
    }
}

@end
