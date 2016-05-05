//
//  ScannerViewController.swift
//
//  Created by Alex
//
//  Copyright (c) 2015 Balancing Rock. All rights reserved.
//
//  Modified for use with BeeBop by Rob Lasell and Ari Scourtas on May 5 2016
//  * Thanks to Sean Deneen for his help adapting this to use NRFManager *
//
//  View Controller that allows the user to view and connect to available
//  bluetooth-capable devices
//
// TODO: connect rescan button with tryAgain method

import UIKit
import CoreBluetooth


class ScannerViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, NRFManagerDelegate {

    // peripheral devices that have been discovered
    var peripherals: [CBPeripheral] = []
    // peripheral the user has selected in the table view
    var selectedPeripheral: CBPeripheral?

    var progressHUD: MBProgressHUD?
    
    // timers to determine when an attempt to scan or connect has timed out
    var scanTimer: NSTimer = NSTimer()
    var connectionTimer: NSTimer = NSTimer()
    
    // storyboard outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rescanButton: UIBarButtonItem!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // rescan button is only enabled when we've stopped scanning
        rescanButton.enabled = false

        // remove extra separator lines for aesthetic purposes
        tableView.tableFooterView = UIView(frame: CGRectZero)

        nrfManager.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // display the connected device (does not happen by default)
        if (nrfManager.connectionStatus == .Connected) {
            peripherals.append(nrfManager.currentPeripheral!.getCBPeripheral())
        }
        
        // start scanning for devices
        nrfManager.scanForPeripherals()
        
        // schedule the scan timeout
        scanTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ScannerViewController.scanTimeout), userInfo: nil, repeats: false)
    }
    
    override func viewWillDisappear(animated : Bool) {
        super.viewWillDisappear(animated)
        
        if (self.isMovingFromParentViewController()){
            nrfManager.stopScanning()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - IBActions
    
    // called when the user presses the rescan button
    @IBAction func tryAgain(sender: AnyObject) {
        // empty array and start again
        peripherals = []
        
        // display the connected device (does not happen by default)
        if (nrfManager.connectionStatus == .Connected) {
            peripherals.append(nrfManager.currentPeripheral!.getCBPeripheral())
        }
        
        tableView.reloadData()

        // begin scanning again
        rescanButton.enabled = false
        nrfManager.scanForPeripherals()
        
        NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ScannerViewController.scanTimeout), userInfo: nil, repeats: false)
    }
    
    
    // MARK: - Timeouts
    
    // scanning should time out if no devices are discovered within 10s
    func scanTimeout() {
        nrfManager.stopScanning()
        // timeout has occurred, stop scanning and give the user the option to try again
        rescanButton.enabled = true
        
        // don't time out if we're already connected
        if nrfManager.connectionStatus == .Connected {
            return
        }
        
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        // display hud message to user
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "No devices detected"
        hud.hide(true, afterDelay: 2)
    }
    
    // connecting should time out if it does not succeed within 10s
    func connectionTimeout() {
        // don't time out if we're already connected
        if nrfManager.connectionStatus == .Connected {
            return
        }
        
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        selectedPeripheral = nil
        
        // display hud message to user
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Failed to connect"
        hud.hide(true, afterDelay: 2)
    }
    
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // number of detected peripherals
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    // cell to return for each peripheral in the table
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BluetoothDeviceCell")!
        cell.textLabel!.text = peripherals[indexPath.row].name
        
        // list the connected device as connected and the others as not connected
        if (nrfManager.currentPeripheral != nil && peripherals[indexPath.row].name == nrfManager.currentPeripheral!.getPeripheralName()) {
            cell.detailTextLabel?.text = "Connected"
        } else {
            cell.detailTextLabel?.text = "Not Connected"
        }

        return cell
    }
    
    
    // MARK: UITableViewDelegate
    
    // called when the user selects a peripheral;
    // connects if the peripheral is not already connected, otherwise disconnects
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // the user has selected a peripheral
        selectedPeripheral = peripherals[indexPath.row]
        
        if (nrfManager.currentPeripheral?.getPeripheralName() != selectedPeripheral!.name) {
            nrfManager.connectPeripheral(selectedPeripheral!)
            
            progressHUD = MBProgressHUD.showHUDAddedTo(view, animated: true)
            progressHUD!.labelText = "Connecting"
            
            connectionTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: #selector(ScannerViewController.connectionTimeout), userInfo: nil, repeats: false)
        } else {
            nrfManager.disconnect()
        }
    }
    
    
    // MARK: - NRFManagerDelegate
    
    // called every time the NRFManager discovers an available bluetooth device
    func nrfDidFindPeripheral(peripheral: CBPeripheral) {
        // do not display duplicates
        for existing in peripherals {
            if existing.identifier == peripheral.identifier {
                return
            }
        }
        
        // do not display unnamed devices
        if (peripheral.name != nil) {
            peripherals.append(peripheral)
        }
        
        tableView.reloadData()
    }
    
    // called when the app successfully connects to a bluetooth device
    func nrfDidConnect(nrfManager: NRFManager) {
        if let hud = progressHUD {
            hud.hide(false)
        }
        
        connectionTimer.invalidate()
        
        // TODO - remove?
        //NSNotificationCenter.defaultCenter().postNotificationName("reloadStartViewController", object: self)
        //dismissViewControllerAnimated(true, completion: nil)
        
        tableView.reloadData()
    }
    
    // called when the app successfully disconnects from a bluetooth device
    func nrfDidDisconnect(nrfManager: NRFManager) {
        //TODO - remove?
        //connectionTimer.invalidate()
        
        tableView.reloadData()
    }
}
