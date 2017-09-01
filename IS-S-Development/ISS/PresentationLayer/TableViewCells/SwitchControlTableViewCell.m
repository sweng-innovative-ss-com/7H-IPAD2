//
//  SwitchControlTableViewCell.m
//  ISS
//
//  Created by Anshuman Dahale on 4/12/17.
//  Copyright © 2017 Digvijay Joshi. All rights reserved.
//

#import "SwitchControlTableViewCell.h"
#import "ApplicationManager.h"
#import "Constants.h"

@implementation SwitchControlTableViewCell


//- (void)drawRect:(CGRect)rect {
//    
//    if(self.cellType == Switch_Cell_Type_InvertColors) {
//        [_switchControl setOn:[ApplicationManager sharedInstance].isDarkMode];
//    }
//    else if (_cellType == Switch_Cell_Type_AES_Encryption) {
//        [_switchControl setOn:[ApplicationManager sharedInstance].shouldEncrypt];
//    }
//}

- (IBAction) invertSwitchValueChanged:(id)sender {
    
//    switch (self.cellType) {
//        case Switch_Cell_Type_InvertColors:
//            {
//                [[ApplicationManager sharedInstance] setIsDarkMode:_switchControl.isOn];
//                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSettingsChanged object:nil];
//            }
//            break;
//        case Switch_Cell_Type_AES_Encryption:
//            {
//                [[ApplicationManager sharedInstance] setShouldEncrypt:_switchControl.isOn];
//            }
//            break;
//        default:
//            break;
//    }
    if([_delegate respondsToSelector:@selector(switchValueChangedTo:forIndexPath:)]) {
        
        [_delegate switchValueChangedTo:_switchControl.isOn forIndexPath:_indexPath];
    }
}


#pragma mark - LifeCycle

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
