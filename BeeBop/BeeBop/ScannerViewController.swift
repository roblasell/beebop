//
//  ScannerViewController.swift
//  HM10 Serial
//
//  Created by Alex on 10-08-15.
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import UIKit
import CoreBluetooth

// TODO will not detect tampering while user is on this page because it doesn't use my custom delegate class
class ScannerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZBluetoothSerialDelegate {

   
//MARK: IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rescanButton: UIBarButtonItem!
    
//MARK: Variables
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    /// The peripheral the user has selected
    var selectedPeripheral: CBPeripheral?
    
    /// Progress hud shown
    var progressHUD: MBProgressHUD?
    
    
//MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // rescanButton is only enabled when we've stopped scanning
        rescanButton.enabled = false

        // remove extra seperator insets (looks better imho)
        //tableView.tableFooterView = UIView(frame: CGRectZero)

        // tell the delegate to notificate US instead of the previous view if something happens
        serial.delegate = self
        
        if serial.state != .PoweredOn {
            // TODO handle bluetooth not being on
            print("Bluetooth not on")
            return
        }
        
        // start scanning and schedule the time out
        serial.scanForPeripherals()
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ScannerViewController.scanTimeOut), userInfo: nil, repeats: false)
    }
    
    // For when back button is pressed
    override func viewWillDisappear(animated : Bool) {
        super.viewWillDisappear(animated)
        
        if (self.isMovingFromParentViewController()){
            // We know back button was pressed
            serial.stopScanning()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Should be called 10s after we've begun scanning
    func scanTimeOut() {
                
        // timeout has occurred, stop scanning and give the user the option to try again
        serial.stopScanning()
        rescanButton.enabled = true
        // TODO handle finish scanning (with popup?)
    }
    
    /// Should be called 10s after we've begun connecting
    func connectTimeOut() {
        
        // don't if we've already connected
        if let _ = serial.connectedPeripheral {
            return
        }
        
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        if let per = selectedPeripheral {
            serial.cancelPeripheralConnection(per)
            selectedPeripheral = nil
        }
        
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Failed to connect"
        hud.hide(true, afterDelay: 2)
    }
    
    
//MARK: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // return a cell with the peripheral name as text in the label
        let cell = tableView.dequeueReusableCellWithIdentifier("cell")!
        let label = cell.viewWithTag(1) as! UILabel!
        label.text = peripherals[indexPath.row].peripheral.name
        return cell
    }
    
    
//MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // the user has selected a peripheral, so stop scanning and proceed to the next view
        serial.stopScanning()
        selectedPeripheral = peripherals[indexPath.row].peripheral
        serial.connectToPeripheral(selectedPeripheral!)
        progressHUD = MBProgressHUD.showHUDAddedTo(view, animated: true)
        progressHUD!.labelText = "Connecting"
        
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "connectTimeOut", userInfo: nil, repeats: false)
    }
    
    
//MARK: DZBluetoothSerialDelegate
    
    func serialHandlerDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber) {
        // check whether it is a duplicate
        for exisiting in peripherals {
            if exisiting.peripheral.identifier == peripheral.identifier { return }
        }
        
        // add to the array, next sort & reload
        peripherals.append(peripheral: peripheral, RSSI: RSSI.floatValue)
        peripherals.sortInPlace { $0.RSSI < $1.RSSI }
        tableView.reloadData()
    }
    
    func serialHandlerDidFailToConnect(peripheral: CBPeripheral, error: NSError?) {
        
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        rescanButton.enabled = true
                
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Failed to connect"
        hud.hide(true, afterDelay: 1.0)
    }
    
    func serialHandlerDidDisconnect(peripheral: CBPeripheral, error: NSError?) {
        
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        rescanButton.enabled = true
        
        deviceStatus = .Disconnected
        
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Failed to connect"
        hud.hide(true, afterDelay: 1.0)

    }
    
    func serialHandlerIsReady(peripheral: CBPeripheral) {
        
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        // Initial connection to device, so change status
        deviceStatus = .Deactivated
        
        NSNotificationCenter.defaultCenter().postNotificationName("reloadStartViewController", object: self)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func serialHandlerDidChangeState(newState: CBCentralManagerState) {
        
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        if newState != .PoweredOn {
            rescanButton.enabled = false
            // TODO handle bluetooth not being turned on
            print("BlueTooth not on")
        } else {
            rescanButton.enabled = true
            // title = "Ready to scan"
            // TODO handle "Ready to scan" (whatever that means)
            print("Ready to rescan")
            
        }
    }
    
    
    

//MARK: IBActions
    @IBAction func tryAgain(sender: AnyObject) {
        // empty array an start again
        peripherals = []
        tableView.reloadData()
        rescanButton.enabled = false
        // title = "Scanning ..." TODO
        serial.scanForPeripherals()
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ScannerViewController.scanTimeOut), userInfo: nil, repeats: false)
    }
    
}
