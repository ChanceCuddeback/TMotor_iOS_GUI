//
//  ViewController.swift
//  TMotorGUI
//
//  Created by Chance on 3/8/21.
//

import UIKit

class ViewController: UIViewController, TMotorDelegate {
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //TMotorPeripheral.delegate? = self
        TMotorPeripheral.shared.startScan(withService: [TMotorPeripheral.TMotorServiceUUID])
        // Do any additional setup after loading the view.
    }
    //MARK: Singleton
    static let shared = ViewController()
    //MARK: Properties
    
    
    //MARK: Computed Variables
    
    
    //MARK: State Variables
    
    
    //MARK: Outlets
    @IBOutlet weak var motor: UISegmentedControl!
    @IBOutlet weak var enableSwitch: UISwitch!
    @IBOutlet weak var mode: UISegmentedControl!
    @IBOutlet weak var setpoint: UISlider!
    @IBOutlet weak var bluetoothInd: UILabel!
    
    //MARK: Actions
    @IBAction func motorChanged(_ sender: UISegmentedControl) {
        
    }
    @IBAction func enableChanged(_ sender: UISwitch) {
        
    }
    @IBAction func modeChanged(_ sender: UISegmentedControl) {
        
    }
    @IBAction func setpointChanged(_ sender: UISlider) {
        
    }
    
    
    //MARK: TMotorDelegate functions
    func TMotorDidConnect() {
        bluetoothInd.textColor = .systemBlue
    }
    
    func TMotorDidDisconnect() {
        bluetoothInd?.textColor = .systemBlue
    }
    
    
}

