//
//  BTCommunicationHandler.swift
//  Bouncer
//
//  Created by Sean Deneen on 4/9/16.
//  Copyright © 2016 Bouncer. All rights reserved.
//
// Handles all communication with the device via BlueTooth, analyzes data, and acts accordingly.

import UIKit
import CoreBluetooth
import QuartzCore

/// The option to add a \n or \r or \r\n to the end of the send message
// TODO remove eventually, came as part of example HM-10 app
enum MessageOption: Int {
    case NoLineEnding = 0
    case Newline = 1
    case CarriageReturn = 2
    case CarriageReturnAndNewline = 3
}

/// The option to add a \n to the end of the received message (to make it more readable)
// TODO remove eventually, came as part of example HM-10 app
enum ReceivedMessageOption: Int {
    case Nothing = 0
    case Newline = 1
}

// Status of the device
enum DeviceStatus: Int {
    case Disconnected = 0
    case Deactivated = 1
    case Activated = 2
    case Alerted = 3
}

// Status of the device (global)
var deviceStatus: DeviceStatus = .Disconnected
// Message received from BT so far, necessary to piece together message fragments
var messageSoFar = ""


class BTCommunicationViewController: UIViewController, DZBluetoothSerialDelegate {
// MARK: Functions
    
    override func viewDidAppear(animated: Bool) {
        serial.delegate = self
    }
    
//MARK: DZBluetoothSerialDelegate

    func serialHandlerDidReceiveMessage(message: String) {
        if (deviceStatus == .Activated) {
            //analyzeSensorData(message)
        }
    }
    
    // TODO replace with push notification alert for testing! So we know right away if it disconnects
    func serialHandlerDidDisconnect(peripheral: CBPeripheral, error: NSError?) {
        // reloadView()
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Disconnected from Device"
        hud.hide(true, afterDelay: 1.0)
        deviceStatus = .Disconnected
    }
    
    
    // TODO same as previous func
    func serialHandlerDidChangeState(newState: CBCentralManagerState) {
        if newState != .PoweredOn {
            let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
            hud.mode = MBProgressHUDMode.Text
            hud.labelText = "Bluetooth turned off"
            hud.hide(true, afterDelay: 1.0)
            deviceStatus = .Disconnected
        }
    }
    
// MARK: Helper Functions

    // Analyzes data to determine whether or not there is tampering and alerts if so
    /*func analyzeSensorData(input: String) {
        // Add message received to whole message
        if (combineMessageFragment(input)) {
            // Only enters in here if we reached the end of the whole message, so messageSoFar has whole message
            print(messageSoFar)
            
            // Convert string accelerometer/gyro data to numerical data in dictionary
            let accelGyroDict: AccelGyroData = createAccelGyroDataDict(messageSoFar)
            let stretchVoltage: Float = getStretchVoltage(messageSoFar)
            
            // As of now, not saving this data to the web server
            // saveSensorData(inputDataDict, stretchVoltage: stretchVoltage)
            
            // Run detection algo
            let detected: Bool = detect(accelGyroDict)
            
            // Alert user if tampering occured
            if (detected) {
                // TODO uncomment next two lines when no longer at restaurant
//                armStatus = .Alerted
//                displayTamperingAlert()
            }
            
            // Reset messageSoFar back to empty string
            messageSoFar = ""
        }
    }
    
    // Inputs from bluetooth arrive all split up like so (looks like a 20 char buffer):
    // -2.00 -11.00 -254.00
    // ;-0.07 -9.09 0.06 0.
    // 00;
    // END
    // So, this func adds a message fragment to the full message unless it is the end character
    // Returns true if message is complete, false otherwise
    func combineMessageFragment(message: String) -> Bool {
        if (message == END_SEPARATOR) {
            let splitVals = messageSoFar.componentsSeparatedByString(GROUP_SEPARATOR)
            if (splitVals.count == NUM_GROUPS_PER_MESSAGE + 1) { // Plus 1 because it adds an extra element at end
                // We have the full message
                return true
            } else {
                // We only got the last part of a message, so clear messageSoFar
                messageSoFar = ""
                return false
            }
        } else {
            messageSoFar += message
            return false
        }
    }
    
    
    // TODO make an alert here
    func displayTamperingAlert() {
//        updateButtonAttributedTitle(mainButton, newTitle: "TAMPERING DETECTED")
//        mainButton.backgroundColor = UIColor.redColor()
        // mainButton.enabled = false
        
        print("alarm!!!")
        deviceStatus = .Alerted
    }
*/
}