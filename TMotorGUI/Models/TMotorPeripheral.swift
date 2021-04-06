//
//  TMotorPeripheral.swift
//  TMotorGUI
//
//  Created by Chance on 3/8/21.
//
import Foundation
import CoreBluetooth

var RSSIConnStrength:NSNumber = -70

//Modified my previous framework, after the nRFBlinky framework
extension Double: DataConvertible { }
extension Int: DataConvertible { }

protocol DataConvertible {
    init?(data: Data)
    var data: Data { get }
}
//An extension of the previous protocol
extension DataConvertible where Self: ExpressibleByIntegerLiteral {
    
    init?(data: Data) {
        var value: Self = 0
        guard data.count == MemoryLayout.size(ofValue: value) else { return nil }
        _ = withUnsafeMutableBytes(of: &value, { data.copyBytes(to: $0)} )
        self = value
    }
    
    var data: Data {
        return withUnsafeBytes(of: self) { Data($0) }
    }
}

protocol TMotorDelegate {
    func TMotorDidConnect()
    func TMotorDidDisconnect()
}

class TMotorPeripheral: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //MARK: Singleton
    //static let shared = TMotorPeripheral();
        
    //MARK: UUIDS
    public static let TMotorServiceUUID = CBUUID.init(string: "12341234-1212-EFDE-1523-785FEABCD120")
    public static let enableCharUUID    = CBUUID.init(string: "12341234-1212-EFDE-1523-785FEABCD121")
    public static let setpointCharUUID  = CBUUID.init(string: "12341234-1212-EFDE-1523-785FEABCD122")
    public static let modeCharUUID      = CBUUID.init(string: "12341234-1212-EFDE-1523-785FEABCD123")
    public static let motorCharUUID     = CBUUID.init(string: "12341234-1212-EFDE-1523-785FEABCD124")
    
    //MARK: Properties
    var LEPeripheral                            : [CBPeripheral]!
    private var centralManager                  : CBCentralManager!
    private var connectedPeripheral             : CBPeripheral?
    private let name = "TMOTOR"
    
    public var controllerDelegate: TMotorDelegate!
    
    //MARK: Computed vars
    private var isConnected: Bool {
        return connectedPeripheral?.state == .connected
    }
    
    //MARK: Characteristic Properties
    private var enableChar  : CBCharacteristic?
    private var setpointChar: CBCharacteristic?
    private var modeChar    : CBCharacteristic?
    private var motorChar   : CBCharacteristic?
    
    
    //MARK: Public API
    
    public func connect(to peripheral:CBPeripheral) {
        centralManager.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    public func disconnect() {
        guard connectedPeripheral != nil else {return}
        centralManager.cancelPeripheralConnection(connectedPeripheral!)
        startScan(withService: [TMotorPeripheral.TMotorServiceUUID])
    }
    
    //MARK: TMotor API
    public func updateMode(to: Mode) -> Bool{
        return charUpdateStatus(forChar: modeChar, with: to.rawValue.data)
    }
    
    public func updateSetpoint(to: Double) -> Bool {
        return charUpdateStatus(forChar: setpointChar, with: to.data)
    }
    
    public func updateEnableStatus(to: Bool) -> Bool {
        var intBool: Int = 0
        if to {intBool = 1}
        return charUpdateStatus(forChar: enableChar, with: intBool.data)
    }
    
    public func updateSelectedMotor(to: Motor) -> Bool {
        return charUpdateStatus(forChar: motorChar, with: to.rawValue.data)
    }
    
    //MARK: Implementation
    private func charUpdateStatus(forChar: CBCharacteristic?, with: Data) -> Bool {
        guard connectedPeripheral != nil else {return false}
        if let char = forChar {
            let props = char.properties
            if props.contains(.write) {
                connectedPeripheral!.writeValue(with, for: char, type: .withResponse)
                return true
            }
        }
        return false
    }
    
    //The function to begin looking for Peripherals
    func startScan(withService service: [CBUUID]? = nil) {
        centralManager.scanForPeripherals(withServices: service, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
    }
    
    
    //MARK: CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScan(withService: [TMotorPeripheral.TMotorServiceUUID])
            print("Scanning")
        }
    }
    //Function that handles when a peripheral is discoverd during scanning
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if LEPeripheral == nil {
            LEPeripheral = [peripheral]
        }
        else if !LEPeripheral.contains(peripheral) {
            LEPeripheral.append(peripheral)
        }
        if (RSSI.compare(RSSIConnStrength) == .orderedDescending) && peripheral.name == name {
            print("Connecting to: \(peripheral)")
            centralManager.connect(peripheral, options: nil)
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        centralManager.stopScan()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([TMotorPeripheral.TMotorServiceUUID])
        controllerDelegate.TMotorDidConnect()
        
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        controllerDelegate.TMotorDidDisconnect()
        startScan()
    }
    
    //MARK: CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("DiscSerErr: \(error!.localizedDescription)")
            return
        }
        guard let services = peripheral.services else {
            print("Error referencing services")
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("DiscCharErr: \(error!.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else {
            print("Error referencing Characteristics")
            return
        }
        for char in characteristics {
            //Assign Characteristics
            switch true {
            case char.uuid.isEqual(TMotorPeripheral.enableCharUUID):
                enableChar = char
                print("Found enableChar")
            case char.uuid.isEqual(TMotorPeripheral.setpointCharUUID):
                setpointChar = char
                print("Found setpointChar")
            case char.uuid.isEqual(TMotorPeripheral.modeCharUUID):
                modeChar = char
                print("Found modeChar")
            case char.uuid.isEqual(TMotorPeripheral.motorCharUUID):
                motorChar = char
                print("Found motorChar")
            default:
                print("Unkown char!")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {return}
        guard characteristic.value != nil else {return}
        print("Got \(characteristic.value!) from \(characteristic)")
    }
}
