//
//  AESKeyViewController.m
//  ISS
//
//  Created by Anshuman Dahale on 3/16/17.
//  Copyright © 2017 Digvijay Joshi. All rights reserved.
//

#import "AESKeyViewController.h"
#import "ApplicationManager.h"
#import "Constants.h"

@interface AESKeyViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation AESKeyViewController


#pragma mark - UITextView Delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    return textView.text.length + (text.length - range.length) <= 12;
}

#pragma mark - IBAction

- (IBAction)doneButton_TouchUpInside:(id)sender {
    
    NSArray *words = [_textView.text componentsSeparatedByCharactersInSet :[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *newKey = [words componentsJoinedByString:@""];
    
    switch (_keyType) {
        case Encryption_Key_Type_AES:
            [[NSUserDefaults standardUserDefaults] setValue:newKey forKey:kUserDefaultsAESKey];
            break;
        
        case Encryption_Key_Type_IV:
            [[NSUserDefaults standardUserDefaults] setValue:newKey forKey:kUserDefaultsIVKey];
            break;
        
        case Encryption_Key_Type_PassCode:
            [[ApplicationManager sharedInstance] setPassCode:newKey];
            break;
        default:
            break;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //3746A0A333656E2A45154567ED5F665B
    
    
    switch (_keyType) {
        case Encryption_Key_Type_AES:
            self.title = @"AES  Key";
            _textView.text = [ApplicationManager sharedInstance].aesKey;
            break;
        
        case Encryption_Key_Type_IV:
            self.title = @"IV Key";
            _textView.text = [ApplicationManager sharedInstance].ivKey;
            break;
            
        case Encryption_Key_Type_PassCode:
            self.title = @"Passcode";
            _textView.text = [ApplicationManager sharedInstance].passCode;
            _textView.delegate = self;
            break;
            
        default:
            break;
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    [_textView resignFirstResponder];
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
