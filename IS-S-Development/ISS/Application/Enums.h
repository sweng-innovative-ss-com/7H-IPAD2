//
//  Enums.h
//  ISS
//
//  Created by Anshuman Dahale on 5/26/16.
//  Copyright © 2016 Digvijay Joshi. All rights reserved.
//

#ifndef Enums_h
#define Enums_h

//Classify the categories in following categories

typedef NS_ENUM (NSInteger, Key_Category) {
    
    Key_Category_Alphabet                   = 0, // A, B ...Z
    Key_Category_Numeric                    = 1, // 0, 1 ..9
    Key_Category_Arrow                      = 2, // <-, ->, up arrow, down arrow
    Key_Category_KeyBoard_Functional        = 3, //Enter, Backspace, +/-, ., /, ZOOM
    Key_Category_Cockpit_Functional         = 4, // XPDR 1, ...VFR
    
    //HomeVC
    Key_Category_Cockpit_Special            = 5, //MAP, FMS ...PREV, NEXT, L PDF, R PDF
    Key_Category_Radio                      = 6  //VOL UP/DN
};


typedef NS_ENUM (NSInteger, Key_State) {
    
    Key_State_Off               = -1,
    Key_State_Default           = 0,  // Normal Background color
    Key_State_Highlighted       = 1,   // Green background color
    Key_State_Special_DN_ON     = 2,
    Key_State_Special_Up_DN_ON  = 3
};


typedef NS_ENUM (NSInteger, Key_Theme) {
    
    Key_Theme_White,
    Key_Theme_LightGray,
    Key_Theme_DarkGray
};

typedef NS_ENUM (NSInteger, Frequency_Type) {
    
    Frequency_Type_COM1,
    Frequency_Type_COM2,
    Frequency_Type_NAV1,
    Frequency_Type_NAV2,
    Frequency_Type_ADF,
    Frequency_Type_TSP
};

typedef NS_ENUM (NSInteger, Encryption_Key_Type) {
    
    Encryption_Key_Type_AES,
    Encryption_Key_Type_IV,
    Encryption_Key_Type_PassCode
};


typedef NS_ENUM(NSInteger, Switch_Cell_Type) {
    
    Switch_Cell_Type_InvertColors = 1,
    Switch_Cell_Type_AES_Encryption = 2
};

#endif /* Enums_h */
