//
//  ScannerViewController.swift
//  HM10 Serial
//
//  Created by Alex and edited by Rob and Ari for use with BeeBop
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//

import UIKit
import CoreBluetooth

class ScannerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, DZBluetoothSerialDelegate {

   
//MARK: IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rescanButton: UIBarButtonItem!
    
//MARK: Scanner Variables
    
    /// The peripherals that have been discovered (no duplicates and sorted by asc RSSI)
    //var peripherals: [(peripheral: CBPeripheral, RSSI: Float)] = []
    var peripherals: [CBPeripheral] = []
    /// The peripheral the user has selected
    var selectedPeripheral: CBPeripheral?
    
    /// Progress hud shown
    var progressHUD: MBProgressHUD?
    
    
//MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // rescanButton is only enabled when we've stopped scanning
        rescanButton.enabled = false

        // remove extra searator lines (looks better)
        tableView.tableFooterView = UIView(frame: CGRectZero)

        // tell the delegate to notificate US instead of the previous view if something happens
        serial.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        if (serial.connectedPeripheral != nil) {
            peripherals.append(serial.connectedPeripheral!)//peripheral: serial.connectedPeripheral., RSSI: RSSI.floatValue)
            //peripherals.sortInPlace { $0.RSSI < $1.RSSI }
        }
        
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
       // print(peripherals.count)
        return peripherals.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // return a cell with the peripheral name as text in the label
        let cell = tableView.dequeueReusableCellWithIdentifier("BluetoothDeviceCell")!
        //let label = cell.viewWithTag(1) as! UILabel!
        //label.text = peripherals[indexPath.row].peripheral.name
        if (peripherals[indexPath.row].name/*peripheral.*/ == "HMSoft") {
            cell.textLabel!.text = "BeeBop"
        } else {
            cell.textLabel!.text = peripherals[indexPath.row].name/*peripheral.*/
        }
        
        if (peripherals[indexPath.row]/*.peripheral*/ == selectedPeripheral ||
            (serial.connectedPeripheral != nil && peripherals[indexPath.row].name == serial.connectedPeripheral!.name)) {//(serial.connectedPeripheral != nil && peripherals[indexPath.row].peripheral.name == serial.connectedPeripheral!.name) {
            cell.detailTextLabel?.text = "Connected"
        } else {
            //print("HERE")
            if (serial.connectedPeripheral != nil) {
                //print(serial.connectedPeripheral!.name)
            } else {
                //print("NO NAME!")
            }
            cell.detailTextLabel?.text = "Not Connected"
        }
        //print (peripherals[indexPath.row].peripheral.name)
        return cell
    }
    
    
//MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // the user has selected a peripheral, so stop scanning and proceed to the next view
        //a "connecting" popup with spinning wheel, returns you to home
        serial.stopScanning()
        selectedPeripheral = peripherals[indexPath.row]//.peripheral
        serial.connectToPeripheral(selectedPeripheral!)
        progressHUD = MBProgressHUD.showHUDAddedTo(view, animated: true)
        progressHUD!.labelText = "Connecting"
        
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ScannerViewController.connectTimeOut), userInfo: nil, repeats: false)
        
        tableView.reloadData()
    }
    
    
//MARK: DZBluetoothSerialDelegate
    
    func serialHandlerDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber) {
        // check whether it is a duplicate
        for existing in peripherals {
            if existing.identifier/*peripheral.*/ == peripheral.identifier { return }
        }
        
        //print("in serialHandlerDidDiscover...")
        
        // add to the array, next sort & reload if the device is named
        //if (peripheral.name != nil) {
        if (peripheral.name != nil) {
            peripherals.append(/*peripheral: */peripheral)//, RSSI: RSSI.floatValue)
            //peripherals.sortInPlace { $0.RSSI < $1.RSSI }
        }

        //print("peripheral to be added", peripheral)
        //print(peripherals)
        
        tableView.reloadData()
    }
    
    func serialHandlerDidFailToConnect(peripheral: CBPeripheral, error: NSError?) {
        
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        if (peripheral == selectedPeripheral) {
            selectedPeripheral = nil
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
        
        if (peripheral == selectedPeripheral) {
            selectedPeripheral = nil
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
