//
//  TMotorPeripheral.swift
//  TMotorGUI
//
//  Created by Chance on 3/8/21.
//
import Foundation
import CoreBluetooth

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

enum modes:Int {
    case position = 0
    case velocity = 1
    case torque   = 2
}

class TMotorPeripheral: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //MARK: Singleton
    static let shared = TMotorPeripheral();
        
    //MARK: UUIDS
    public static let TMotorServiceUUID = CBUUID.init(string: "12341234-1212-EFDE-1523-785FEABCD120")
    public static let enableCharUUID    = CBUUID.init(string: "12341234-1212-EFDE-1523-785FEABCD121")
    public static let setpointCharUUID  = CBUUID.init(string: "12341234-1212-EFDE-1523-785FEABCD122")
    public static let modeCharUUID      = CBUUID.init(string: "12341234-1212-EFDE-1523-785FEABCD123")
    
    //MARK: Properties
    var LEPeripheral                            : [CBPeripheral]!
    private var centralManager                  : CBCentralManager!
    private var connectedPeripheral             : CBPeripheral?
    private let name = "TMOTOR"
    
    public static var delegate: TMotorDelegate?
    
    //MARK: Computed vars
    private var isConnected: Bool {
        return connectedPeripheral?.state == .connected
    }
    
    //MARK: Characteristic Properties
    private var enableChar  : CBCharacteristic?
    private var setpointChar: CBCharacteristic?
    private var modeChar    : CBCharacteristic?
    
    
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
    public func changeMode(to: modes) {
        guard connectedPeripheral != nil else {return}
        if let modeChar = modeChar {
            if modeChar.properties.contains(.write) {
                print("Changing mode characteristic...")
                let data = to.rawValue.data
                connectedPeripheral!.writeValue(data, for: modeChar, type: .withoutResponse)
            } else {
                print("Can't change mode!")
            }
        }
    }
    
    //MARK: Implementation
    //The function to begin looking for Peripherals
    func startScan(withService service: [CBUUID]? = nil) {
        centralManager.scanForPeripherals(withServices: service, options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
    }
    
    
    //MARK: CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("State updated to \(central.state)")
        if central.state == .poweredOn {
            startScan(withService: [TMotorPeripheral.TMotorServiceUUID])
            print("Scanning")
        }
    }
    //Function that handles when a peripheral is discoverd during scanning
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Found: \(peripheral)")
        if LEPeripheral == nil {
            LEPeripheral = [peripheral]
        }
        else if !LEPeripheral.contains(peripheral) {
            LEPeripheral.append(peripheral)
        }
        if (RSSI.compare(-60) == .orderedDescending) && peripheral.name == name {
            print("Connecting to: \(peripheral)")
            centralManager.connect(peripheral, options: nil)
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        centralManager.stopScan()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([TMotorPeripheral.TMotorServiceUUID])
        print("Connected!")
        //Horrible code, but this is for an ME Capstone
        //ViewController.shared.bluetoothInd.textColor = .systemIndigo
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        startScan()
        //ViewController.shared.bluetoothInd.textColor = .black
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
