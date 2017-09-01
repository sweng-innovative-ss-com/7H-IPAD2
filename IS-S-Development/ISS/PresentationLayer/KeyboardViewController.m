//
//  KeyboardViewController.m
//  ISS
//
//  Created by Digvijay Joshi on 5/20/16.
//  Copyright © 2016 Digvijay Joshi. All rights reserved.
//

#import "KeyboardViewController.h"
#import "ApplicationManager.h"
#import "KeyBoardButton.h"
#import "KeyHexConverter.h"
#import "BluetoothManager.h"
#import "TrackPadView.h"
#import "Enums.h"
#import "Constants.h"
#import "Utility.h"

#define ZOOM_KEY_CODE @"0x81"

@interface KeyboardViewController () <TouchCoordinatesDelegate, ReadResponseDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, retain) KeyHexConverter *keyHexConverter;
@property (nonatomic, retain) BluetoothManager *bluetoothManager;
@property (nonatomic, strong) NSMutableArray *clickedButtons;
@property (nonatomic, strong) NSMutableArray *allKeys;
@property (nonatomic)         BOOL hasRotatedOnce;
@property (nonatomic, strong) IBOutlet TrackPadView *trackPad;
@property (nonatomic, strong) IBOutlet UILabel *modelNameLabel;
@property (nonatomic, strong) IBOutlet UIView *keyBoardContainerView, *zoomButtonView, *arrowView;
@property (nonatomic, strong) IBOutlet UIButton *settingsButton;

@property (nonatomic, strong) Utility *utility;

@end

@implementation KeyboardViewController


#pragma mark - IBActions
- (IBAction)settingsButton_TouchUpInside:(id)sender {
    
    [UIView animateWithDuration:0.5 animations:^{
        
        _settingsButton.transform = CGAffineTransformMakeRotation(M_PI/4);
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSettingsClicked object:nil];
    }];
}

- (void) settingsIconRotateBackToOriginal {
    
    [UIView animateWithDuration:0.5 animations:^{
        _settingsButton.transform = CGAffineTransformMakeRotation(-M_PI/4);
    }];
}

#pragma mark - Helper

- (void) updateColorForAllKeys {
    UIImage *image = [UIImage imageNamed:[ApplicationManager sharedInstance].isDarkMode ? @"setting-white" : @"setting-black"];
    [_settingsButton setImage:image forState:UIControlStateNormal];
    [self changeKeyColorsForKeysInArray:_allKeys];
}

- (void) changeKeyColorsForKeysInArray:(NSArray *)keysArray {
    
    for(KeyBoardButton *aKey in keysArray) {
        
//        NSLog(@"Changing color for: %@", aKey.keyName);
        //Set the delegate to self
        aKey.delegate = self;
        [aKey updateTheme];
    }
}

#pragma mark - BluetoothManager Delegate

- (void) readValueKeyHex:(NSString *)keyHex forState:(Key_State)keyState {
    
    if(keyHex) {
    
        NSArray *matchingKeyNameArray = [_keyHexConverter getKeyForHexValue:keyHex];
        if([matchingKeyNameArray count]) {
            
            if([keyHex isEqualToString:ZOOM_KEY_CODE]) {
                
                switch (keyState) {
                    
                    case Key_State_Default:
                        {
                            [self changeStateTo:Key_State_Default forKeysInArray:[_utility getMatchingButtonsForKeyName:@"KEY_ZOOM_IN" inArray:_allKeys]];
                            
                            [self changeStateTo:Key_State_Default forKeysInArray:[_utility getMatchingButtonsForKeyName:@"KEY_ZOOM_OUT" inArray:_allKeys]];
                        }
                        break;
                        
                    case Key_State_Highlighted:
                        {
                            [self changeStateTo:Key_State_Highlighted forKeysInArray:[_utility getMatchingButtonsForKeyName:@"KEY_ZOOM_IN" inArray:_allKeys]];
                            
                            [self changeStateTo:Key_State_Default forKeysInArray:[_utility getMatchingButtonsForKeyName:@"KEY_ZOOM_OUT" inArray:_allKeys]];
                        }
                        break;
                        
                    case Key_State_Special_DN_ON:
                        {
                            
                            [self changeStateTo:Key_State_Default forKeysInArray:[_utility getMatchingButtonsForKeyName:@"KEY_ZOOM_IN" inArray:_allKeys]];
                            
                            [self changeStateTo:Key_State_Highlighted forKeysInArray:[_utility getMatchingButtonsForKeyName:@"KEY_ZOOM_OUT" inArray:_allKeys]];
                        }
                        break;
                        
                    case Key_State_Special_Up_DN_ON:
                        {
                            [self changeStateTo:Key_State_Highlighted forKeysInArray:[_utility getMatchingButtonsForKeyName:@"KEY_ZOOM_IN" inArray:_allKeys]];
                            
                            [self changeStateTo:Key_State_Highlighted forKeysInArray:[_utility getMatchingButtonsForKeyName:@"KEY_ZOOM_OUT" inArray:_allKeys]];
                        }
                        break;
                        
                    default:
                        break;
                }
            }
            
            else {
                
                NSString *keyName = [matchingKeyNameArray objectAtIndex:0];
                NSArray *keys = [self getMatchingButtonsForKeyName:keyName inArray:_allKeys];
                [self changeStateTo:keyState forKeysInArray:keys];
            }
        }
    }
}


#pragma mark - Trackpad Delegate

- (void) userTouchedOnPoint:(CGPoint)touchPoint {
    
    //NSLog(@"X: %f  Y:%f", touchPoint.x, touchPoint.y);
    [_bluetoothManager  writeTrackPadCoordinates:touchPoint
                        withSuccessBlock:nil];
}


#pragma mark - KeyBoardButtonDelegate

- (void) userPressedKey:(KeyBoardButton *)pressedKey {
    
//    NSLog(@"-------------------------------------\n");
//    NSLog(@"Pressed Key: %@", pressedKey.keyName);
    NSString *valueOfPressedKey =    [_keyHexConverter  getValueForKey:pressedKey.keyName
                                                        category:pressedKey.keyCategory];
    Key_State state = pressedKey.keyState;
    
    if ([pressedKey.keyName isEqualToString:@"KEY_ZOOM_IN"]) {
        valueOfPressedKey = ZOOM_KEY_CODE;
        state = Key_State_Highlighted;
    }
    else if ([pressedKey.keyName isEqualToString:@"KEY_ZOOM_OUT"]) {
        valueOfPressedKey = ZOOM_KEY_CODE;
        state = Key_State_Off;
    }
    
    if(_bluetoothManager.isConnected) {
        
        [_bluetoothManager writeToPeripheralValue:valueOfPressedKey forState:state withSuccessBlock:^(NSError *error, BOOL success) {
        }];
    }
}


#pragma mark - Helper

- (void) markButttonsAsClickedAfterOrientationChange {
    
    //NSLog(@"In markButttonsAsClickedAfterOrientationChange");
    NSArray *copyOfClickedButtons = [[NSArray alloc] initWithArray:_clickedButtons];
    for(KeyBoardButton *clickedButton in copyOfClickedButtons) {
       
       NSArray *matchingKeysArray = [self getMatchingButtonsForKeyName:clickedButton.keyName inArray:_allKeys];
       [self changeStateTo:Key_State_Highlighted forKeysInArray:matchingKeysArray];
   }
}

- (NSArray *) getMatchingButtonsForKeyName:(NSString *)keyName inArray:(NSArray *)array {

    NSString *nameMatchingPredicateString = [NSString stringWithFormat:@"keyName == '%@'", keyName];
    NSPredicate *nameMatchPredicate = [NSPredicate predicateWithFormat:nameMatchingPredicateString];
    NSArray *matchingKeysArray = [array filteredArrayUsingPredicate:nameMatchPredicate];
    //NSLog(@"Matching Keys: %@", matchingKeysArray);
    return matchingKeysArray;
}

- (void) changeStateTo:(Key_State)state forKeysInArray:(NSArray *)keysArray {
    
    for(KeyBoardButton *aKey in keysArray) {
        
        aKey.keyState = state;
        [aKey updateTheme];
        
        if(aKey.keyState == Key_State_Default) {
            [_clickedButtons removeObject:aKey];
        }
        else if(aKey.keyState == Key_State_Highlighted) {
            
            if(![_clickedButtons containsObject:aKey]) {
                [_clickedButtons addObject:aKey];
            }
        }
    }
}


- (void) leftSwipeGestureDetected {
    
//    NSLog(@"User swiped right");
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationLeftGesture object:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    if(touch.view == _trackPad) {
        return NO;
    }
    return YES;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UISwipeGestureRecognizer *swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipeGestureDetected)];
    swipeGestureRecognizer.delegate = self;
    swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:swipeGestureRecognizer];
    
    _utility = [[Utility alloc] init];
    _allKeys = [[NSMutableArray alloc] init];
    
    [_utility getAllButtonsFromView:self.view withComplitionBlock:^(NSArray *keysArray) {
        
        _allKeys = [NSMutableArray arrayWithArray:keysArray];
        [self updateColorForAllKeys];
    }];
    
    _trackPad.touchDelegate = self;
    _clickedButtons = [[NSMutableArray alloc] init];
    _keyHexConverter = [[KeyHexConverter alloc] init];
    
    _bluetoothManager = [BluetoothManager sharedInstance];
    _bluetoothManager.keyBoardReadDelegate = self;

    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(updateColorForAllKeys)
        name:kNotificationSettingsChanged
        object:nil];
    
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(settingsIconRotateBackToOriginal)
        name:kNotificationSettingsViewClosed
        object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    //NSLog(@"In viewWillAppear");
    [[NSNotificationCenter defaultCenter]   addObserver:self
                                            selector:@selector(orientationChanged:)
                                            name:UIDeviceOrientationDidChangeNotification
                                            object:nil];
}

- (void) orientationChanged:(NSNotification *)notification {
   
   float delay = _hasRotatedOnce ? 0.0 : 1.0;
   
   [self    performSelector:@selector(markButttonsAsClickedAfterOrientationChange)
            withObject:nil
            afterDelay:delay];
    
    _hasRotatedOnce = YES;
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
