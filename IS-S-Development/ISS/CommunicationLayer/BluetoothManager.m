//
//  BluetoothManager.m
//  BluetoothTest
//
//  Created by Anshuman Dahale on 5/26/16.
//  Copyright © 2016 Silicus. All rights reserved.
//

#import "BluetoothManager.h"
#import "Constants.h"
#import "Enums.h"
#import "NSString+Conversion.h"
#import "Crypt.h"
#import "KeyHexConverter.h"
#import "SlipEnocding.h"
#import "ApplicationManager.h"
#import <CommonCrypto/CommonCrypto.h>


#define MAX_MSG_POINTER         5
#define BLE_KEY_HEADER          0xFD
#define KEY_PASSCODE            0x84
#define KEY_CCD_DELTA_CODE      0x85


@interface BluetoothManager ()

@property (nonatomic, strong) CBCentralManager  *centralManager;
@property (nonatomic, strong) CBPeripheral      *connectedPeriferal;
@property (nonatomic, strong) CBCharacteristic  *txCharacteristic;
@property (nonatomic, strong) CBCharacteristic  *rxCharacteristic;

@property (nonatomic, strong) ConnectionBlock   connectionBlock;
@property (nonatomic, strong) SuccessBlock      writeSuccessBlock;
@property (nonatomic, strong) DeviceListBlock   discoveredDevicesBlock;

@property (nonatomic, strong) NSMutableData     *messageData;
@property (nonatomic, strong) NSMutableArray    *discoveredDevicesArray;

@property (nonatomic, strong) KeyHexConverter   *keyHexConverter;
@property (nonatomic, strong) SlipEnocding      *slipEncoding;

@end


@implementation BluetoothManager


- (void) getPeripheralListWithComplitionBlock:(DeviceListBlock) complitionBlock {
    
    _discoveredDevicesArray = [[NSMutableArray alloc] init];
    [self disconnect];
    _discoveredDevicesBlock = complitionBlock;
    [self startScan];
}

- (void) connectToPeripheral:(CBPeripheral *)periferal WithConnectionBlock:(ConnectionBlock)connectionBlock {
    
    _discoveredDevicesBlock = nil;
    _connectionBlock = connectionBlock;
    [_centralManager connectPeripheral:periferal options:nil];
}


+ (BluetoothManager *) sharedInstance {
    
    static BluetoothManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedInstance = [[BluetoothManager alloc] init];
        sharedInstance.centralManager = [[CBCentralManager alloc] initWithDelegate:sharedInstance queue:nil];
        sharedInstance.keyHexConverter = [[KeyHexConverter alloc] init];
        sharedInstance.slipEncoding  = [[SlipEnocding alloc] init];
    });
    
    return sharedInstance;
}

- (void) connectWithResponseBlock:(ConnectionBlock)responseBlock {

    _connectionBlock = responseBlock;
    [self startScan];
}

- (void) disconnect {
    
    if(_connectedPeriferal != nil) {
        [self.centralManager cancelPeripheralConnection:_connectedPeriferal];
    }
}

- (void) startScan {

    // Scan for all available CoreBluetooth LE devices
    NSArray *services = @[
        [CBUUID UUIDWithString:UUID_UART_SERVICES]
    ];
    [self.centralManager scanForPeripheralsWithServices:services options:nil];
}


- (void) sendPassCodeKeyToPeripheral {
    
    unsigned char passCodeMessage[16];
    passCodeMessage[0] = 0xFD;
    passCodeMessage[1] = KEY_PASSCODE;
    
    NSString *userSetPassCode = [ApplicationManager sharedInstance].passCode;
    for(int passCodeMessageNdx = 2, userSetPassCodeNdx = 0; passCodeMessageNdx < 14; passCodeMessageNdx++) {
        
        if(userSetPassCodeNdx < userSetPassCode.length) {
            
            NSString *string = [NSString stringWithFormat:@"%c",[userSetPassCode characterAtIndex:userSetPassCodeNdx]];
            NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
            uint8_t *uintBit = (uint8_t*)stringData.bytes;
            passCodeMessage[passCodeMessageNdx] = *uintBit;
            userSetPassCodeNdx++;
        }
        else {
            passCodeMessage[passCodeMessageNdx] = 0;
        }
    }
    //Set the last bit as
    passCodeMessage[14] = 0;
    
    //Calculation checksum
    unsigned char sum = passCodeMessage[0];
    for(int i = 1; i < 15; i++) {
        sum = sum + passCodeMessage[i];
    }
    sum = (~sum) + 1;
    passCodeMessage[15] = sum;
    
    NSData *passcodeData = [NSData dataWithBytes:(const void*) passCodeMessage length:16];
    [self.connectedPeriferal writeValue:[self getAES128EncryptedForData:passcodeData]
                            forCharacteristic:_txCharacteristic
                            type:CBCharacteristicWriteWithResponse];
}

- (void) processForPassCodeWithData:(NSData *)data {
    
    unsigned char *dataArray = (unsigned char *)[data bytes];
    if([data length] == 5) {
        //Validate if bits at 3 & 4 position are 0
        if((dataArray[2] == 0) && (dataArray[3] == 00)) {
            
            //calculate and check if checksum is correct
            unsigned char checksum = ~ (dataArray[0] + dataArray[1] + dataArray[2] + dataArray[3]) + 1;
            if(checksum == dataArray[4]) {
                [self sendPassCodeKeyToPeripheral];
            }
        }
    }
}



//BOOL headerFound;


- (void) processPacket:(NSData *)packet {
    
//    NSLog(@"Processing perfect packet: %@", packet);
    NSData *data = [self getAES128DecryptedForData:packet];  // Recieved message
    NSUInteger dataLength = [data length];         // Length of the message

    unsigned char *dataArray = (unsigned char *)[data bytes];
    
    if(dataLength > 2) {
        if(dataArray[1] == KEY_PASSCODE) {
            [self processForPassCodeWithData:data];
            return;
        }
    }
    
    unsigned char checksum;
    int startNdx;
    int keycodeNdx;
    int stateNdx;
    
    unsigned char fifo[5];
    int fifoPointer = 0;
//    NSLog(@"FiFo Pointer Before for: %d", fifoPointer);
//    fifoPointer = 0;
    for(int i=0; i<dataLength; i++) {
        
        fifo[fifoPointer] = dataArray[i];
        fifoPointer = (fifoPointer+1) % MAX_MSG_POINTER;
        checksum = 0;
        
        for (int j = 0; j < MAX_MSG_POINTER; j++) {
            checksum += fifo[j];
        }
//        NSLog(@"CheckSum in recieved message: %d", checksum);
        if (0 == checksum) // possible message found
        {
            // the next byte should be start of message
            startNdx    = fifoPointer;
            keycodeNdx  = fifoPointer + 1;
            stateNdx    = fifoPointer + 2;
            
            if (BLE_KEY_HEADER == fifo[startNdx]) {
                // we found a message, if AND only if the keycode is valid
                //
                // Value at 1st location is the Key
                
                NSString *actualKey = [[NSString stringWithFormat:@"%2x", fifo[keycodeNdx]] uppercaseString];
                NSString *keyHex = [NSString stringWithFormat:@"0x%@", actualKey];
                
                keyHex = [keyHex stringByReplacingOccurrencesOfString:@" " withString:@"0"];

                // Value at the 2nd location is state of the key
                NSUInteger keyState = [[NSNumber numberWithUnsignedChar:fifo[stateNdx]] integerValue];
                
//                NSLog(@"Found Key is: %@ with state: %lu", keyHex, (unsigned long)keyState);
                //Pass this value to the object listening to this delegate
                
                if(keyHex) {
                    
                    Key_Category category = [_keyHexConverter getCategoryForHexValue:keyHex];
                    
                    if(category >= 0) {
                        
                        switch (category) {
                                
                            case Key_Category_Alphabet:
                            case Key_Category_KeyBoard_Functional:
                            case Key_Category_Numeric:
                            case Key_Category_Arrow:
                                if ([_keyBoardReadDelegate respondsToSelector:@selector(readValueKeyHex:forState:)]) {
                                    [_keyBoardReadDelegate readValueKeyHex:keyHex forState:keyState];
                                }
                                break;
                                
                            case Key_Category_Cockpit_Special:
                                if ([_homeReadDelegate respondsToSelector:@selector(readValueKeyHex:forState:)]) {
                                    [_homeReadDelegate readValueKeyHex:keyHex forState:keyState];
                                }
                                break;
                                
                            case Key_Category_Cockpit_Functional:
                                if ([_tspReadDelegate respondsToSelector:@selector(readValueKeyHex:forState:)]) {
                                    [_tspReadDelegate readValueKeyHex:keyHex forState:keyState];
                                }
                                break;
                                
                            case Key_Category_Radio:
                                if([_radioReadDelegate respondsToSelector:@selector(readValueKeyHex:forState:)]) {
                                    [_radioReadDelegate readValueKeyHex:keyHex forState:keyState];
                                }
                            default:
                                break;
                        }
                    }
                }
                //This packet is processed, no more need to check if checksum is 0
                break;
            }
        }
    }
}




- (void) processRead:(CBCharacteristic *)characteristic {
    
    NSData *recievedData = [characteristic value];
    //Verify that we havent recieved nil, as it will cause a crash.
    if((recievedData != nil) && recievedData.length > 0) {
        
//        NSLog(@"Recieved Chunk: %@", recievedData);
        unsigned char *dataArray = (unsigned char *)[recievedData bytes];
        
        for(int i = 0; i < recievedData.length; i++) {
            
            UInt8 aBit = dataArray[i];
            NSData *aBitData = [[NSData alloc] initWithBytes:&aBit length:sizeof(aBit)];
            
            if(dataArray[i] == 0xC0) {
            
                if(_messageData == nil) {
                    //Its the begining of a new packet
//                    NSLog(@"New packet. C0 recieved");
                    _messageData = [[NSMutableData alloc] initWithData:aBitData];
                }
                else {
//                    NSLog(@"Append Bit");
                    [_messageData appendData:aBitData];

                    if(_messageData.length > 2) {
                        
//                        NSLog(@"Perfect packet formed. FW to process: %@", _messageData);
                        NSData *deepCopy = [[NSData alloc] initWithBytes:[_messageData bytes] length:_messageData.length];
                        _messageData = nil;
                        [self processPacket:deepCopy];
                    }
                    else {
//                        NSLog(@"Packet has C0 at either end but length less than 2. Discard it");
                        _messageData = nil;
                        _messageData = [[NSMutableData alloc] initWithData:aBitData];
                    }
                }
            }
            else if(_messageData != nil) {
//                NSLog(@"Append Bit");
                [_messageData appendData:aBitData];
            }
        }
    }
}

#pragma mark - AES Encryption

- (NSData *) getAES128EncryptedForData:(NSData *)data {
    
    if([ApplicationManager sharedInstance].shouldEncrypt == YES) {
        
        NSData *keyHex  = [Crypt dataFromHexString:[ApplicationManager sharedInstance].aesKey];
        NSData *ivHex   = [Crypt dataFromHexString:[ApplicationManager sharedInstance].ivKey];
        NSError *error = nil;
        NSData *encryptedData = [Crypt aes128Data:data operation:kCCEncrypt key:keyHex options:kCCOptionPKCS7Padding iv:ivHex error:&error];
        return [_slipEncoding SLIPEncodeData:encryptedData];
        //    NSLog(@"Data to write (RAW) : %@", data);
        //    NSLog(@"Data to write (AES) : %@", encryptedData);
        //    NSLog(@"Data to write (SLIP): %@", slipEncodedData);
        //    NSLog(@"Data Length: %lu",(unsigned long)slipEncodedData.length);
    }
    
    else {
        return [_slipEncoding SLIPEncodeData:data];
    }
    return nil;
}


- (NSData *) getAES128DecryptedForData:(NSData *)encryptedData {
    
    if([ApplicationManager sharedInstance].shouldEncrypt) {
        
        NSData *slipDecryptedData = [_slipEncoding SLIPDecodeData:encryptedData];
        NSData *keyHex  = [Crypt dataFromHexString:[ApplicationManager sharedInstance].aesKey];
        NSData *ivHex   = [Crypt dataFromHexString:[ApplicationManager sharedInstance].ivKey];
        NSError *error;
        NSData *aesDecrypted = [Crypt aes128Data:slipDecryptedData operation:kCCDecrypt key:keyHex options:kCCOptionPKCS7Padding iv:ivHex error:&error];
        //    NSLog(@"Data to process (AES): %@", encryptedData);
        //    NSLog(@"Data to process (RAW): %@", aesDecrypted);
        return aesDecrypted;
    }
    
    else {
        return [_slipEncoding SLIPDecodeData:encryptedData];
    }
    return nil;
}

#pragma mark - Radio Write

- (void) writeRadioFrequency:(NSArray *)frequencyArray forFrequencyType:(Frequency_Type)freqType {
    
    //Frequency Type
    //COM1 = 1
    //COM2 = 2
    //NAV1 = 3
    //NAV2 = 4
    //ADF  = 5
    
    //TSP dont have freq type
    
    NSInteger packetLength = (freqType == Frequency_Type_TSP) ? frequencyArray.count+3 : frequencyArray.count+4;
    
    unsigned char message [packetLength];
    
    message[0] = 0xFD;      //Marks the begining of a packet
    
    NSInteger startFromIndex = 0;
    
    if(freqType == Frequency_Type_TSP) {
        message[1] = 0x83;      //Constant for TSP frequency
        startFromIndex = 2;
    }
    else {
        message[1] = 0x80;      //Constant for all Radio (page) Frequencys
        message[2] = freqType;  //FrequencyType
        startFromIndex = 3;
    }
    
    for(NSInteger charId=0, pointer = startFromIndex; charId<frequencyArray.count; charId++, pointer++) {
        
        NSString *string = [frequencyArray objectAtIndex:charId];
        message[pointer] = [string hexToInteger];
    }
    
    //Calculation checksum
    unsigned char sum = message[0];
    for(int i = 1; i < packetLength-1; i++) {
        sum = sum + message[i];
    }
    sum = (~sum) + 1;
    
    //set the checksum as last bit in the array
    message[packetLength-1] = sum;
    
    NSData *data = [NSData dataWithBytes:(const void*)message length:packetLength];
    
    [self.connectedPeriferal    writeValue:[self getAES128EncryptedForData:data]
                                forCharacteristic:_txCharacteristic
                                type:CBCharacteristicWriteWithResponse];
}


- (void) writeFltPlnInput:(NSArray *)input withSuccessBlock:(SuccessBlock)successBlock {
    
    _writeSuccessBlock = successBlock;
    
    NSInteger packetLength = input.count + 5;
    uint8_t inputLength = input.count;
    
    unsigned char message [packetLength];
    message[0] = 0xFD;      //Marks the begining of a packet
    message[1] = 0x82;
    message[2] = 0x00;
    message[3] = inputLength;

    
    for(NSInteger charId=0, pointer = 4; charId<input.count; charId++, pointer++) {
        
        NSString *string = [input objectAtIndex:charId];

        NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
        uint8_t *uintBit = (uint8_t*)stringData.bytes;
        message[pointer] = *uintBit;
//        printf("\nMessage Pointer: %c", message[pointer]);
    }

    //Calculation checksum
    unsigned char sum = message[0];
    for(int i = 1; i < packetLength-1; i++) {
        sum = sum + message[i];
    }
    sum = (~sum) + 1;
    
    //set the checksum as last bit in the array
    message[packetLength-1] = sum;
    
    NSData *data = [NSData dataWithBytes:(const void*)message length:packetLength];
    NSData *encryptedData = [self getAES128EncryptedForData:data];
    
    
    //Break the packet into smaller packets
    if(encryptedData.length > 18) {
        
        int numberOfChunks = (encryptedData.length % 18 == 0) ? encryptedData.length/18 : 1.0 +(encryptedData.length/18);
        int startIndex = 0;
        int chunkLength = 18;
        
//        NSLog(@"Number of chunks to form: %d", numberOfChunks);
        
        for(int i = 0; i < numberOfChunks; i++) {
    
            chunkLength = ((startIndex + chunkLength) > encryptedData.length) ? (encryptedData.length - startIndex) : 18;
//            NSLog(@"Start Index: %d", startIndex);
//            NSLog(@"Chunk Length = %d", chunkLength);
            
            NSData *chunk = [encryptedData subdataWithRange:NSMakeRange(startIndex, chunkLength)];
            [self.connectedPeriferal    writeValue:chunk
                                forCharacteristic:_txCharacteristic
                                type:CBCharacteristicWriteWithResponse];
            startIndex = startIndex + chunkLength;
        }
    }
    else {
    
        [self.connectedPeriferal    writeValue:encryptedData
                                forCharacteristic:_txCharacteristic
                                type:CBCharacteristicWriteWithResponse];
    }
}


#pragma mark - KeyBoard Write

- (void) writeTrackPadCoordinates:(CGPoint)point withSuccessBlock:(SuccessBlock)successBlock {

//    NSString *keyCode = @"KEY_CCD";
    
    static unsigned char message[7];
    
    uint8_t *plusBit    = (uint8_t *)[@"+" dataUsingEncoding:NSUTF8StringEncoding].bytes;
    uint8_t *minusBit   = (uint8_t *)[@"-" dataUsingEncoding:NSUTF8StringEncoding].bytes;
    
    message[0] = 0xFD;
    message[1] = KEY_CCD_DELTA_CODE;//[keyCode hexToInteger];
    message[2] = (point.x > 0) ? *plusBit : *minusBit;
    message[3] = (point.x > 0) ? point.x : -point.x;
    message[4] = (point.y > 0) ? *plusBit : *minusBit;
    message[5] = (point.y > 0) ? point.y : -point.y;
    message[6] = ~( message[0] + message[1] + message[2] + message[3] + message[4] + message[5]) + 1;
    
    NSInteger messageSize = sizeof(message);
    NSData *data = [NSData dataWithBytes:(const void*) message length:messageSize];
    
    [self.connectedPeriferal writeValue:[self getAES128EncryptedForData:data]
                            forCharacteristic:_txCharacteristic
                            type:CBCharacteristicWriteWithResponse];
}


- (void) writeToPeripheralValue:(NSString *)hexValue forState:(Key_State)state withSuccessBlock:(SuccessBlock)writeSuccessBlock {
    
    static unsigned char message[5];
    
    message[0] = 0xFD;
    message[1] = [hexValue hexToInteger]; //(unsigned int)[hexValue UTF8String];
    message[2] = state; // for CCD keycode, zero otherwise, one for the highlight color (green) on the keyboard
    message[3] = 0; // for CCD keycode, zero otherwise
    message[4] = ~ (message[0] + message[1] + message[2] + message[3]) + 1;
    
    NSInteger messageSize = sizeof(message);
    NSData *data = [NSData dataWithBytes:(const void*) message length:messageSize];
    NSLog(@"Data Sent: %@", data);
    [self.connectedPeriferal writeValue:[self getAES128EncryptedForData:data]
                            forCharacteristic:_txCharacteristic
                            type:CBCharacteristicWriteWithResponse];
    
    _writeSuccessBlock = writeSuccessBlock;
}


#pragma mark - CBCentralManagerDelegate
// This method is invoked after a @link readValueForCharacteristic: @/link call, or upon receipt of a notification/indication.
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    if([characteristic.UUID isEqual:_rxCharacteristic.UUID]) {
        
//        NSLog(@"DidUpdateValueForCharacteristic: %@", characteristic.value);
        [self processRead:characteristic];
    }
}

// method called whenever you have successfully connected to the BLE peripheral
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
    _connectedPeriferal = peripheral;
    [ApplicationManager sharedInstance].deviceName = peripheral.name;
    // Notify the caller that the device is connected
    _connectionBlock(nil, peripheral.name);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    
//    NSLog(@"Bluetooth connection terminated with error: %@", error.description);
    [ApplicationManager sharedInstance].deviceName = @"";
    _isConnected = NO;
    _connectionBlock(error,@"");
    [self startScan];
}

 
// CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    if(_discoveredDevicesBlock == nil) {
        NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
        localName = [[localName substringToIndex:3] uppercaseString];
        NSString *adaFruitDeviceName = @"Adafruit Bluefruit LE";
        adaFruitDeviceName = [[adaFruitDeviceName substringToIndex:3] uppercaseString];
        if([localName isEqualToString:@"MFD"] || [localName isEqualToString:adaFruitDeviceName]) {
            
            //NSLog(@"Found the device: %@", localName);
            [self.centralManager stopScan];
            peripheral.delegate = self;
            [self.centralManager connectPeripheral:peripheral options:nil];
        }
    }
    else {
        NSLog(@"%@", peripheral.identifier);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self.identifier == %@", peripheral.identifier];
        if([_discoveredDevicesArray filteredArrayUsingPredicate:predicate].count == 0) {
            
            [_discoveredDevicesArray addObject:peripheral];
            _discoveredDevicesBlock(nil, _discoveredDevicesArray);
        }
    }
}
 
// method called whenever the device state changes.
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSError *error = nil;
    
    // Determine the state of the peripheral
    if ([central state] == CBCentralManagerStatePoweredOff) {
    
        NSLog(@"CoreBluetooth BLE hardware is powered off");
        error = [NSError errorWithDomain:@"CoreBluetooth BLE hardware is powered off" code:4001 userInfo:nil];
    }
    
    else if ([central state] == CBCentralManagerStatePoweredOn) {
        
        [self startScan];
        NSLog(@"CoreBluetooth BLE hardware is powered on and ready");
    }
    
    else if ([central state] == CBCentralManagerStateUnauthorized) {
        
        NSLog(@"CoreBluetooth BLE state is unauthorized");
        error = [NSError errorWithDomain:@"CoreBluetooth BLE state is unauthorized" code:4002 userInfo:nil];
    }
    
    else if ([central state] == CBCentralManagerStateUnknown) {
        
        NSLog(@"CoreBluetooth BLE state is unknown");
        error = [NSError errorWithDomain:@"CoreBluetooth BLE state is unknown" code:4003 userInfo:nil];
    }
    
    else if ([central state] == CBCentralManagerStateUnsupported) {
    
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
        error = [NSError errorWithDomain:@"CoreBluetooth BLE hardware is unsupported on this platform" code:4004 userInfo:nil];
    }
    
    if(error) {
        _connectionBlock(error, @"");
    }
}


#pragma mark - CBPeripheralDelegate
 
// CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    
    // Scan the device for available services
    for (CBService *service in peripheral.services) {
        NSLog(@"Discovered service: %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}
 
// Invoked when you discover the characteristics of a specified service.
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    
    NSLog(@"");
    for(CBCharacteristic *aCharacteristic in service.characteristics) {
        
        if([aCharacteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_Tx_CHARACTERISTIC]]) {
            
            _isConnected = YES;
            _txCharacteristic = aCharacteristic;
        }
        
        if([aCharacteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_Rx_CHARACTERISTIC]]) {
            _rxCharacteristic = aCharacteristic;
            [self.connectedPeriferal readValueForCharacteristic:_rxCharacteristic];
            [self.connectedPeriferal setNotifyValue:YES forCharacteristic:_rxCharacteristic];
        }
        
        NSLog(@"Discovered characteristic: %@",aCharacteristic.UUID);
    }
}


- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    if(error) {
        NSLog(@"Error occured while writing characteristic: %@", error.domain);
        if(_writeSuccessBlock) {
            _writeSuccessBlock(error, NO);
        }
    }
    
    else {
//        NSLog(@"Wrote successfully...");
        if(_writeSuccessBlock) {
            _writeSuccessBlock(nil, YES);
        }
    }
    _writeSuccessBlock = nil;
}

@end
