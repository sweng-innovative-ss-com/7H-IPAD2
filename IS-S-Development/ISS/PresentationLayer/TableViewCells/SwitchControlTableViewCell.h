//
//  SwitchControlTableViewCell.h
//  ISS
//
//  Created by Anshuman Dahale on 4/12/17.
//  Copyright © 2017 Digvijay Joshi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Enums.h"

@protocol SwitchControlTableViewCellProtocol <NSObject>

- (void) switchValueChangedTo:(BOOL)value forIndexPath:(NSIndexPath *)indexPath;

@end


@interface SwitchControlTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UISwitch *switchControl;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic) Switch_Cell_Type cellType;
@property (nonatomic) id<SwitchControlTableViewCellProtocol> delegate;

@end
