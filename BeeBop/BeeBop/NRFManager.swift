//
//  NRFManager.swift
//  nRF8001-Swift
//
//  Originally created by Michael Teeuw on 31-07-14.
//  Copyright (c) 2014 Michael Teeuw. All rights reserved.
//
//  Modified for use with BeeBop by Rob Lasell, Ari Scourtas, and Sean Deneen on May 4 2016
//

import Foundation
import CoreBluetooth


public enum ConnectionMode {
    case None
    case PinIO
    case UART
}

public enum ConnectionStatus {
    case Disconnected
    case Scanning
    case Connected
}


// MARK: - NRFManagerDelegate Definition

@objc public protocol NRFManagerDelegate {
    optional func nrfDidConnect(nrfManager:NRFManager)
    optional func nrfDidDisconnect(nrfManager:NRFManager)
    optional func nrfReceivedData(nrfManager:NRFManager, data:NSData?, string:String?)
    optional func nrfDidFindPeripheral(peripheral:CBPeripheral)
    optional func nrfDidUpdateStatus(nrfManager:NRFManager, state: CBCentralManagerState)
}


/*!
 *  @class NRFManager
 *  @discussion The manager for nRF8001 connections.
 */

// MARK: - NRFManager

public class NRFManager:NSObject, CBCentralManagerDelegate, UARTPeripheralDelegate {
    
    // Private Properties
    
    private var bluetoothManager:CBCentralManager!
    
    //Public Properties
    
    // currently connected bluetooth device
    public var currentPeripheral: UARTPeripheral? {
        didSet {
            if let p = currentPeripheral {
                p.verbose = self.verbose
            }
        }
    }
    
    public var verbose = false
    public var autoConnect = true
    public var delegate:NRFManagerDelegate?
    
    public var connectionCallback:(()->())?
    public var disconnectionCallback:(()->())?
    public var dataCallback:((data:NSData?, string:String?)->())?
    
    public private(set) var connectionMode = ConnectionMode.None
    public private(set) var connectionStatus:ConnectionStatus = ConnectionStatus.Disconnected {
        didSet {
            if connectionStatus != oldValue {
                switch connectionStatus {
                case .Connected:
                    
                    connectionCallback?()
                    delegate?.nrfDidConnect?(self)
                    
                default:
                    
                    disconnectionCallback?()
                    delegate?.nrfDidDisconnect?(self)
                }
            }
        }
    }

    
    public class var sharedInstance : NRFManager {
        struct Static {
            static let instance : NRFManager = NRFManager()
        }
        return Static.instance
    }
    
    public init(delegate:NRFManagerDelegate? = nil, onConnect connectionCallback:(()->())? = nil, onDisconnect disconnectionCallback:(()->())? = nil, onData dataCallback:((data:NSData?, string:String?)->())? = nil, autoConnect:Bool = false)
    {
        super.init()
        self.delegate = delegate
        self.autoConnect = autoConnect
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        self.connectionCallback = connectionCallback
        self.disconnectionCallback = disconnectionCallback
        self.dataCallback = dataCallback
    }
}


// MARK: Private Methods

extension NRFManager {
    
    private func alertBluetoothPowerOff() {
        print("NRFManager: Bluetooth disabled")
        disconnect()
    }
    
    private func alertFailedConnection() {
        print("NRFManager: Unable to connect");
    }
}


// MARK: Public Methods

extension NRFManager {
    
    // search for available bluetooth devices
    public func scanForPeripherals() {
        bluetoothManager.scanForPeripheralsWithServices([UARTPeripheral.uartServiceUUID()], options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
    }
    
    // stop searching for bluetooth devices
    public func stopScanning() {
        bluetoothManager.stopScan()
    }
    
    // connect to a specific bluetooth device
    public func connectPeripheral(peripheral:CBPeripheral) {
        // nullify any previous connection
        bluetoothManager.cancelPeripheralConnection(peripheral)
        
        currentPeripheral = UARTPeripheral(peripheral: peripheral, delegate: self)
        
        bluetoothManager.connectPeripheral(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey:false])
    }
    
    // disconnect from currently connected device
    public func disconnect() {
        // asked to disconnect but no device is connected
        if currentPeripheral == nil {
            return
        }
        
        bluetoothManager.cancelPeripheralConnection((currentPeripheral?.peripheral)!)
    }
    
    // send a message containing a string to the connected bluetooth device
    public func writeString(string:String) -> Bool {
        if let currentPeripheral = self.currentPeripheral {
            if connectionStatus == .Connected {
                currentPeripheral.writeString(string)
                return true
            }
        }
        
        // can't send string/no connection
        return false
    }
    
    // send a message containing NSData to the connected bluetooth device
    public func writeData(data:NSData) -> Bool {
        if let currentPeripheral = self.currentPeripheral {
            if connectionStatus == .Connected {
                currentPeripheral.writeRawData(data)
                return true
            }
        }
        
        // can't send data/no connection
        return false
    }
}


// MARK: CBCentralManagerDelegate Methods

extension NRFManager {
    
    // called when the CBCentralManager changes state
    public func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == .PoweredOn { // bluetooth capability turned on
            // do anything that needs to be done
        } else if central.state == .PoweredOff { // bt capability turned off
            connectionStatus = ConnectionStatus.Disconnected
            connectionMode = ConnectionMode.None
        }
        
        self.delegate!.nrfDidUpdateStatus!(self, state: central.state)
    }
    
    // called any time the CBCentralManager is looking for bluetooth devices
    // and discovers an available device
    public func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
    {
        delegate?.nrfDidFindPeripheral!(peripheral)
    }
    
    // called when the CBCentralManager successfully connects to a bluetooth device
    public func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        if currentPeripheral?.peripheral == peripheral {
            if (peripheral.services) != nil {
                currentPeripheral?.peripheral(peripheral, didDiscoverServices: nil)
            } else {
                currentPeripheral?.didConnect()
            }
        }
    }
    
    // called when the CBCentralManager successfully disconnects from a bluetooth device
    public func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?)
    {
        if currentPeripheral?.peripheral == peripheral {
            connectionStatus = ConnectionStatus.Disconnected
            connectionMode = ConnectionMode.None
            currentPeripheral = nil
        }
    }
}


// MARK: UARTPeripheralDelegate Methods

extension NRFManager {
    
    // called when receiving a message over bluetooth from the connected device
    public func didReceiveData(newData:NSData) {
        if connectionStatus == .Connected || connectionStatus == .Scanning {
            let string = NSString(data: newData, encoding:NSUTF8StringEncoding)
            
            self.delegate?.nrfReceivedData?(self, data:newData, string: string as? String)
        }
    }
    
    public func didReadHardwareRevisionString(string:String) {
        connectionStatus = .Connected
    }
    
    public func uartDidEncounterError(error:String) {
        print("NRFManager: uartDidEncounterError:", error)
    }
}


/*!
 *  @class UARTPeripheral
 *
 *  @discussion The peripheral object used by NRFManager.
 *
 */

// MARK: - UARTPeripheral

public class UARTPeripheral:NSObject, CBPeripheralDelegate {
    
    private var peripheral:CBPeripheral
    private var uartService:CBService?
    private var rxCharacteristic:CBCharacteristic?
    private var txCharacteristic:CBCharacteristic?
    
    private var delegate:UARTPeripheralDelegate
    private var verbose = false
    
    
    private init(peripheral:CBPeripheral, delegate:UARTPeripheralDelegate) {
        
        self.peripheral = peripheral
        self.delegate = delegate
        
        super.init()
        
        self.peripheral.delegate = self
    }
}


// MARK: Private Methods

extension UARTPeripheral {
    
    private func compareID(firstID:CBUUID, toID secondID:CBUUID)->Bool {
        return firstID.UUIDString == secondID.UUIDString
        
    }
    
    private func setupPeripheralForUse(peripheral:CBPeripheral) {
        if let services = peripheral.services {
            for service:CBService in services {
                if let characteristics = service.characteristics {
                    for characteristic:CBCharacteristic in characteristics {
                        if compareID(characteristic.UUID, toID: UARTPeripheral.rxCharacteristicsUUID()) {
                            rxCharacteristic = characteristic
                            peripheral.setNotifyValue(true, forCharacteristic: rxCharacteristic!)
                        } else if compareID(characteristic.UUID, toID: UARTPeripheral.txCharacteristicsUUID()) {
                            txCharacteristic = characteristic
                        } else if compareID(characteristic.UUID, toID: UARTPeripheral.hardwareRevisionStringUUID()) {
                            peripheral.readValueForCharacteristic(characteristic)
                        }
                    }
                }
            }
        }
    }
    
    private func didConnect() {
        if peripheral.services != nil {
            print("UARTPeripheral: Skipping service discovery for:", peripheral.name)
            peripheral(peripheral, didDiscoverServices: nil)
            return
        }
        
        peripheral.discoverServices([UARTPeripheral.uartServiceUUID(), UARTPeripheral.deviceInformationServiceUUID()])
    }
    
    private func writeString(string:String) {
        let data = NSData(bytes: string, length: string.characters.count)
        writeRawData(data)
    }
    
    private func writeRawData(data:NSData) {
        if let txCharacteristic = self.txCharacteristic {
            if txCharacteristic.properties.intersect(.WriteWithoutResponse) != [] {
                peripheral.writeValue(data, forCharacteristic: txCharacteristic, type: .WithoutResponse)
            } else if txCharacteristic.properties.intersect(.Write) != [] {
                peripheral.writeValue(data, forCharacteristic: txCharacteristic, type: .WithResponse)
            } else {
                print("UARTPeripheral: No write property on TX characteristics:", txCharacteristic.properties)
            }
        }
    }
}


// MARK: CBPeripheralDelegate methods

extension UARTPeripheral {
    
    public func getPeripheralName() -> String {
        return peripheral.name!
    }
    
    public func getCBPeripheral() -> CBPeripheral {
        return peripheral
    }
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverServices error:NSError?) {
        
        if error == nil {
            if let services = peripheral.services {
                for service:CBService in services {
                    if service.characteristics != nil {
                        //var e = NSError()
                        //peripheral(peripheral, didDiscoverCharacteristicsForService: s, error: e)
                    } else if compareID(service.UUID, toID: UARTPeripheral.uartServiceUUID()) {
                        uartService = service
                        peripheral.discoverCharacteristics([UARTPeripheral.txCharacteristicsUUID(),UARTPeripheral.rxCharacteristicsUUID()], forService: uartService!)
                    } else if compareID(service.UUID, toID: UARTPeripheral.deviceInformationServiceUUID()) {
                        peripheral.discoverCharacteristics([UARTPeripheral.hardwareRevisionStringUUID()], forService: service)
                    }
                }
            }
        } else {
            print("UARTPeripheral: CBPeripheral: Error discovering services:", error)
            delegate.uartDidEncounterError("Error discovering services")
            return
        }
    }
    
    public func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?)
    {
        if error  == nil {
            if let services = peripheral.services {
                let s = services[services.count - 1]
                if compareID(service.UUID, toID: s.UUID) {
                    setupPeripheralForUse(peripheral)
                }
            }
        } else {
            print("UARTPeripheral: Error discovering characteristics:", error)
            delegate.uartDidEncounterError("Error discovering characteristics")
            return
        }
    }
    
    public func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?)
    {
        if error == nil {
            if characteristic == rxCharacteristic {
                if let value = characteristic.value {
                    delegate.didReceiveData(value)
                }
            } else if compareID(characteristic.UUID, toID: UARTPeripheral.hardwareRevisionStringUUID()){
                delegate.didReadHardwareRevisionString(NSString(CString:characteristic.description, encoding: NSUTF8StringEncoding)! as String)
            }
        } else {
            print("UARTPeripheral: CBPeripheral: Error receiving notification for characteristic:", error)
            delegate.uartDidEncounterError("Error receiving notification for characteristic")
            return
        }
    }
}


// MARK: Class Methods

extension UARTPeripheral {
    class func uartServiceUUID() -> CBUUID {
        return CBUUID(string:"6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    }
    
    class func txCharacteristicsUUID() -> CBUUID {
        return CBUUID(string:"6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    }
    
    class func rxCharacteristicsUUID() -> CBUUID {
        return CBUUID(string:"6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    }
    
    class func deviceInformationServiceUUID() -> CBUUID{
        return CBUUID(string:"180A")
    }
    
    class func hardwareRevisionStringUUID() -> CBUUID{
        return CBUUID(string:"2A27")
    }
}


// MARK: UARTPeripheralDelegate Definition

private protocol UARTPeripheralDelegate {
    func didReceiveData(newData:NSData)
    func didReadHardwareRevisionString(string:String)
    func uartDidEncounterError(error:String)
}