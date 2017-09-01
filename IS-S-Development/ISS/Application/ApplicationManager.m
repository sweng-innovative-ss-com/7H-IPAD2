//
//  ApplicationManager.m
//  ISS
//
//  Created by Anshuman Dahale on 5/26/16.
//  Copyright © 2016 Digvijay Joshi. All rights reserved.
//

#import "ApplicationManager.h"
#import "Constants.h"
#import "BluetoothManager.h"

@implementation ApplicationManager

+ (ApplicationManager *) sharedInstance {
    
    static ApplicationManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[ApplicationManager alloc] init];
    });
    
    return sharedInstance;
}

- (NSString *) aesKey {
    
    NSString *key = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsAESKey];
    return (key.length) ? key : @"3746A0A333656E2A45154567ED5F665B";
}

- (NSString *) ivKey {
    
    NSString *key = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsIVKey];
    return (key.length) ? key : @"93F1E5D61F17E48F0669E2DF1DF5EA0C";
}

- (NSString *) deviceName {
    
    return _deviceName;
}

//5 50 1
// Radio frequency spacing
- (NSString *) comSpacing {

    NSString *value = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsComSpacing];
    if(value.length <= 0) {
        value = @"5";
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:kUserDefaultsComSpacing];
    }
    return value;
}

- (NSString *) passCode {
    
    NSString *passCode = [[NSUserDefaults standardUserDefaults] valueForKey:kPassCodeDefaultsKey];
    if(passCode.length <= 0) {
        //by default 12 0's
        passCode = @"000000000000";
        [[NSUserDefaults standardUserDefaults] setValue:passCode forKey:kPassCodeDefaultsKey];
    }
    return passCode;
}

- (void) setPassCode:(NSString *)passCode {
    
    [[NSUserDefaults standardUserDefaults] setValue:passCode forKey:kPassCodeDefaultsKey];
}

- (NSString *) navSpacing {
    
    NSString *value = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsNAVSpacing];
    if(value.length <= 0) {
        value = @"50";
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:kUserDefaultsNAVSpacing];
    }
    return value;
}

- (NSString *) adfSpacing {
    
    NSString *value = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsADFSpacing];
    if(value.length <= 0) {
        value = @"1";
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:kUserDefaultsADFSpacing];
    }
    return value;
}

- (BOOL) isDarkMode {

    BOOL darkMode = [[NSUserDefaults standardUserDefaults] boolForKey:kIsDarkModeDefaultsKey];
    return darkMode;
}

- (void) setIsDarkMode:(BOOL)isDarkMode {
    
    [[NSUserDefaults standardUserDefaults] setBool:isDarkMode forKey:kIsDarkModeDefaultsKey];
}

- (BOOL) shouldEncrypt {
    
    if(![[NSUserDefaults standardUserDefaults] valueForKey:kShouldEncryptDefaultsKey]) {
    
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShouldEncryptDefaultsKey];
    }
    
    BOOL encryptBool = [[NSUserDefaults standardUserDefaults] boolForKey:kShouldEncryptDefaultsKey];
    return encryptBool;
}

- (void) setShouldEncrypt:(BOOL)shouldEncrypt {
    
    [[NSUserDefaults standardUserDefaults] setBool:shouldEncrypt forKey:kShouldEncryptDefaultsKey];
}


@end
