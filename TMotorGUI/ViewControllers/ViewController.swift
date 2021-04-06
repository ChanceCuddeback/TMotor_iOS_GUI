//
//  ViewController.swift
//  TMotorGUI
//
//  Created by Chance on 3/8/21.
//

import UIKit


enum Mode:Int {
    case position = 0
    case velocity = 1
    case torque   = 2
}

enum Motor:Int {
    case left   = 0
    case right  = 1
}

struct MotorConstraints {
    let posMax:Double = 12
    let posMin:Double = -12
    
    let velMax:Double = 5
    let velMin:Double = -5
    
    let torMax:Double = 5
    let torMin:Double = -5
}



class ViewController: UIViewController {
    
    let Constraints = MotorConstraints()
    
    var nano33:TMotorPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()
        nano33 = TMotorPeripheral()
        nano33?.controllerDelegate = self
        nano33?.startScan(withService: [TMotorPeripheral.TMotorServiceUUID])
        //TMotorPeripheral.shared.startScan(withService: [TMotorPeripheral.TMotorServiceUUID])
    }
    //MARK: Singleton
    //static let shared = ViewController()
    
    
    
    //MARK: Computed state properties
    var selectedMotor: Motor {
        get {
            return Motor(rawValue: motor.selectedSegmentIndex)!
        }
        set {
            //Update bluetooth goodies
            if !nano33!.updateSelectedMotor(to: newValue) {
                print("Failure to update Selected Motor!")
            }
        }
    }
    
    var motorsEnabled: Bool {
        get {
            return enableSwitch.isOn
        }
        set {
            if !nano33!.updateEnableStatus(to: newValue) {
                print("Failure to update Enable status!")
            }
        }
    }
    
    var selectedMode:Mode {
        get {
            return Mode(rawValue: mode.selectedSegmentIndex)!
        }
        set {
            updateSlider(for_Mode: newValue)
            if !nano33!.updateMode(to: newValue) {
                print("Failure to update Mode!")
            }
        }
    }
    
    
    
    //MARK: Outlets
    @IBOutlet weak var motor: UISegmentedControl!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var mode: UISegmentedControl!
    @IBOutlet weak var setpoint: UISlider!
    @IBOutlet weak var bluetoothInd: UILabel!
    
    //MARK: Actions
    @IBAction func motorChanged(_ sender: UISegmentedControl) {
        selectedMotor = Motor(rawValue: motor.selectedSegmentIndex)!
    }
    
    @IBAction func enableChanged(_ sender: UISwitch) {
        motorsEnabled = enableSwitch.isOn
    }
    
    @IBAction func modeChanged(_ sender: UISegmentedControl) {
        selectedMode = Mode(rawValue: mode.selectedSegmentIndex)!
    }
    
    @IBAction func setpointChanged(_ sender: UISlider) {
        guard nano33 != nil else {
            print("Cannot send new setpoint when nano33 is nil.")
            return
        }
        if !nano33!.updateSetpoint(to: Double(setpoint.value)) {
            print("Error updating Setpoint!")
        }
    }
    
    //MARK: Slider function
    func updateSlider(for_Mode: Mode) {
        let mode = for_Mode
        let max: Double
        let min: Double
        switch mode {
        case .position:
            max = Constraints.posMax
            min = Constraints.posMin
        case .velocity:
            max = Constraints.velMax
            min = Constraints.velMin
        case .torque:
            max = Constraints.torMax
            min = Constraints.torMin
        }
        setpoint.maximumValue = Float(max)
        setpoint.minimumValue = Float(min)
        setpoint.value = 0
    }
}


extension ViewController:TMotorDelegate {
    //MARK: TMotorDelegate functions
    func TMotorDidConnect() {
        print("Got Connection!")
        bluetoothInd?.textColor = .systemBlue
    }
    
    func TMotorDidDisconnect() {
        print("Got Diconnection!")
        bluetoothInd?.textColor = .systemGray
    }
}

