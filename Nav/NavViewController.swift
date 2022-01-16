//
//  NavViewController.swift
//  Nav
//
//  Created by 賴奕翔 on 2021/2/2.
//
//

import UIKit
import RBSManager

class NavViewController: UIViewController, RBSManagerDelegate, UITextFieldDelegate {
    // MARK: - Declare
    // user interface
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var connectButton: UIButton!
    
    // direction control
    @IBOutlet var velForwardButton: UIButton!
    @IBOutlet var velBackButton: UIButton!
    @IBOutlet var velLeftButton: UIButton!
    @IBOutlet var velRightButton: UIButton!
    @IBOutlet var velStopButton: UIButton!
    
    // tool bar button
    var backButton: UIBarButtonItem?
    var hostButton: UIBarButtonItem?
    var stopButton: UIBarButtonItem?
    var flexibleToolbarSpace: UIBarButtonItem?
    
    // speed view
    @IBOutlet var linearLabel: UILabel!
    @IBOutlet var angularLabel: UILabel!
    
    // input (x,y)
    @IBOutlet var xTextField: UITextField!
    @IBOutlet var yTextField: UITextField!
    
    // goal
    @IBOutlet var goalLabel: UILabel!
    @IBOutlet var sendGoalButton: UIButton!
    
    //system control
    @IBOutlet var closeParticleButton: UIButton!
    @IBOutlet var openParticleButton: UIButton!
    @IBOutlet var resetOdomButton: UIButton!
    @IBOutlet var clearLidarButton: UIButton!
    
    // console log
    @IBOutlet var consoleLogTextView: UITextView!
    
    // RBSManager
    var turtleManager: RBSManager?
    var cmdVelPublisher: RBSPublisher?
    var stopPublisher: RBSPublisher?
    var goalPublisher: RBSPublisher?
    var systemPublisher: RBSPublisher?
    
    // user settings
    var socketHost: String?

    // data handling
    let MaxLinearSpeed: Float64 = 1
    let MaxAngularSpeed: Float64 = 3
    var linearSpeed: Float64 = 0
    var angularSpeed: Float64 = 0
    
    var consoleLog = ""
    
    let second: Double = 1000000
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = []
        turtleManager = RBSManager.sharedManager()
        turtleManager?.delegate = self
        updateButtonStates(false)
        
        // load settings to retrieve the stored host value
        loadSettings()
        
        // add toolbar buttons
        backButton = UIBarButtonItem(title: "back", style: .plain, target: self, action: #selector(onBackButton))
        stopButton = UIBarButtonItem(title: "stop", style: .plain, target: self, action: #selector(onStopButton))
        hostButton = UIBarButtonItem(title: "Host", style: .plain, target: self, action: #selector(onHostButton))
        flexibleToolbarSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        updateToolbarItems()
        
        // create the publisher
        cmdVelPublisher = turtleManager?.addPublisher(topic: "/cmd_vel", messageType: "geometry_msgs/Twist", messageClass: TwistMessage.self)
        stopPublisher = turtleManager?.addPublisher(topic: "/stop", messageType: "std_msgs/String", messageClass: StringMessage.self)
        goalPublisher = turtleManager?.addPublisher(topic: "/destination", messageType: "std_msgs/String", messageClass: StringMessage.self)
        systemPublisher = turtleManager?.addPublisher(topic: "/function", messageType: "std_msgs/String", messageClass: StringMessage.self)
        
        //textField setting
        xTextField.delegate = self
        yTextField.delegate = self
        
        // button setting
        sendGoalButton.layer.borderWidth = 3/UIScreen.main.nativeScale
        sendGoalButton.layer.borderColor = UIColor.systemBlue.cgColor
        closeParticleButton.layer.borderWidth = 3/UIScreen.main.nativeScale
        closeParticleButton.layer.borderColor = UIColor.systemBlue.cgColor
        openParticleButton.layer.borderWidth = 3/UIScreen.main.nativeScale
        openParticleButton.layer.borderColor = UIColor.systemBlue.cgColor
        resetOdomButton.layer.borderWidth = 3/UIScreen.main.nativeScale
        resetOdomButton.layer.borderColor = UIColor.systemBlue.cgColor
        clearLidarButton.layer.borderWidth = 3/UIScreen.main.nativeScale
        clearLidarButton.layer.borderColor = UIColor.systemBlue.cgColor
        
        usleep(useconds_t(0.05*second))
        consoleLogTextView.scrollRangeToVisible(NSMakeRange(consoleLogTextView.text.count-1, 1))
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        xTextField.resignFirstResponder()
        yTextField.resignFirstResponder()
        goalLabel.text = "Goal : ( \(xTextField.text ?? "0") , \(yTextField.text ?? "0") )"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Socket setting
    func loadSettings() {
        print("loadSettings")
        let defaults = UserDefaults.standard
        socketHost = defaults.string(forKey: "socket_host")
    }
    
    func saveSettings() {
        print("saveSettings")
        let defaults = UserDefaults.standard
        defaults.set(socketHost, forKey: "socket_host")
    }
    
    @objc func onHostButton() {
        // change the host used by the websocket
        let alertController = UIAlertController(title: "Enter socket host", message: "IP or name of ROS master", preferredStyle: UIAlertController.Style.alert)
        alertController.addTextField { (textField : UITextField) -> Void in
            textField.placeholder = "Host"
            textField.text = self.socketHost
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (result : UIAlertAction) -> Void in
        }
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (result : UIAlertAction) -> Void in
            if let textField = alertController.textFields?.first {
                self.socketHost = textField.text
                self.saveSettings()
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
   
    
    // MARK: - Manager
    func managerDidConnect(_ manager: RBSManager) {
        updateButtonStates(true)
        updateToolbarItems()
        
        // retrieve the colours used by the background
        //retrieveColourParameters()
    }
    
    func manager(_ manager: RBSManager, threwError error: Error) {
        if (manager.connected == false) {
            updateButtonStates(false)
        }
        print(error.localizedDescription)
    }
    
    func manager(_ manager: RBSManager, didDisconnect error: Error?) {
        updateButtonStates(false)
        updateToolbarItems()
        print(error?.localizedDescription ?? "connection did disconnect")
    }

    

    
    
    // MARK: - Connect setting
    @IBAction func onConnectButton() {
        if turtleManager?.connected == true {
            turtleManager?.disconnect()
        } else {
            if socketHost != nil {
                // the manager will produce a delegate error if the socket host is invalid
                turtleManager?.connect(address: socketHost!)
            } else {
                // print log error
                print("Missing socket host value --> use host button")
            }
        }
    }
    
    // update interface for the different connection statuses
    func updateButtonStates(_ connected: Bool) {
        velForwardButton.isEnabled = connected
        velBackButton.isEnabled = connected
        velLeftButton.isEnabled = connected
        velRightButton.isEnabled = connected
        velStopButton.isEnabled = connected
        sendGoalButton.isEnabled = connected
        closeParticleButton.isEnabled = connected
        openParticleButton.isEnabled = connected
        resetOdomButton.isEnabled = connected
        clearLidarButton.isEnabled = connected

        velForwardButton.alpha = velForwardButton.isEnabled ? 1 : 0.4
        velBackButton.alpha = velBackButton.isEnabled ? 1 : 0.4
        velLeftButton.alpha = velLeftButton.isEnabled ? 1 : 0.4
        velRightButton.alpha = velRightButton.isEnabled ? 1 : 0.4
        velStopButton.alpha = velStopButton.isEnabled ? 1 : 0.4
        sendGoalButton.alpha = sendGoalButton.isEnabled ? 1 : 0.4
        closeParticleButton.alpha = closeParticleButton.isEnabled ? 1 : 0.4
        openParticleButton.alpha = openParticleButton.isEnabled ? 1 : 0.4
        resetOdomButton.alpha = resetOdomButton.isEnabled ? 1 : 0.4
        clearLidarButton.alpha = clearLidarButton.isEnabled ? 1 : 0.4
        
        if connected {
            let redColor = UIColor(red: 0.729, green: 0.131, blue: 0.144, alpha: 1.0)
            connectButton.backgroundColor = redColor
            connectButton.setTitle("DISCONNECT", for: .normal)
            consoleLogTextView.text = consoleLogTextView.text + "\nCONNECT"
            usleep(useconds_t(0.05*second))
            consoleLogTextView.scrollRangeToVisible(NSMakeRange(consoleLogTextView.text.count-1, 1))
        } else {
            let greenColor = UIColor(red: 0.329, green: 0.729, blue: 0.273, alpha: 1.0)
            connectButton.backgroundColor = greenColor
            connectButton.setTitle("CONNECT", for: .normal)
            consoleLogTextView.text = consoleLogTextView.text + "\nDISCONNECT"
            usleep(useconds_t(0.05*second))
            consoleLogTextView.scrollRangeToVisible(NSMakeRange(consoleLogTextView.text.count-1, 1))
        }
    }
    
    func updateToolbarItems() {
        if turtleManager?.connected == true {
            toolbar.setItems([flexibleToolbarSpace!,stopButton!], animated: false)
        } else {
            toolbar.setItems([backButton!,flexibleToolbarSpace!, hostButton!], animated: false)
        }
    }
    
    
    // MARK: - Button activative
    @objc func onStopButton() {
        let message = StringMessage()
        message.data = "stop"
        stopPublisher?.publish(message)
        consoleLogTextView.text = consoleLogTextView.text +  "\n" + message.data!
        usleep(useconds_t(0.1*second))
        consoleLogTextView.scrollRangeToVisible(NSMakeRange(consoleLogTextView.text.count-1, 1))
    }
    
    @IBAction func onVelForwardButton(_ sender: Any) {
        let message = TwistMessage()
        linearSpeed = (linearSpeed + 0.1)<=MaxLinearSpeed ? linearSpeed + 0.1:linearSpeed
        message.linear?.x = linearSpeed
        message.angular?.z = angularSpeed
        cmdVelPublisher?.publish(message)
        
        print("linear = "+String(format: "%.1f", linearSpeed)+" angular = "+String(format: "%.1f", angularSpeed))
        linearLabel.text = String(format: "%.1f", linearSpeed)
        angularLabel.text = String(format: "%.1f", angularSpeed)
    }
    
    @IBAction func onVelbackButton(_ sender: Any) {
        let message = TwistMessage()
        linearSpeed = -(linearSpeed - 0.1)<=MaxLinearSpeed ? linearSpeed - 0.1:linearSpeed
        message.linear?.x = linearSpeed
        message.angular?.z = angularSpeed
        cmdVelPublisher?.publish(message)
        
        print("linear = "+String(format: "%.1f", linearSpeed)+" angular = "+String(format: "%.1f", angularSpeed))
        linearLabel.text = String(format: "%.1f", linearSpeed)
        angularLabel.text = String(format: "%.1f", angularSpeed)
    }
    
    @IBAction func onVelLeftButton(_ sender: Any) {
        let message = TwistMessage()
        angularSpeed = (angularSpeed+0.1)<=MaxAngularSpeed ? angularSpeed + 0.1:angularSpeed
        message.linear?.x = linearSpeed
        message.angular?.z = angularSpeed
        cmdVelPublisher?.publish(message)
        
        print("linear = "+String(format: "%.1f", linearSpeed)+" angular = "+String(format: "%.1f", angularSpeed))
        linearLabel.text = String(format: "%.1f", linearSpeed)
        angularLabel.text = String(format: "%.1f", angularSpeed)
    }
    
    @IBAction func onVelRightButton(_ sender: Any) {
        let message = TwistMessage()
        angularSpeed = -(angularSpeed-0.1)<=MaxAngularSpeed ? angularSpeed - 0.1:angularSpeed
        message.linear?.x = linearSpeed
        message.angular?.z = angularSpeed
        cmdVelPublisher?.publish(message)
        
        print("linear = "+String(format: "%.1f", linearSpeed)+" angular = "+String(format: "%.1f", angularSpeed))
        linearLabel.text = String(format: "%.1f", linearSpeed)
        angularLabel.text = String(format: "%.1f", angularSpeed)
    }
    
    @IBAction func onVelStopButton(_ sender: Any) {
        let message = TwistMessage()
        linearSpeed = 0
        angularSpeed = 0
        message.linear?.x = 0.0
        message.angular?.z = 0.0
        cmdVelPublisher?.publish(message)
        
        print("linear = "+String(format: "%.1f", linearSpeed)+" angular = "+String(format: "%.1f", angularSpeed))
        linearLabel.text = String(format: "%.1f", linearSpeed)
        angularLabel.text = String(format: "%.1f", angularSpeed)
    }
    
    @IBAction func onSendGoalButton(_ sender: Any) {
        goalLabel.text = "Goal : ( \(xTextField.text ?? "0") , \(yTextField.text ?? "0") )"
        let message = StringMessage()
        message.data = "\(xTextField.text ?? "0"), \(yTextField.text ?? "0")"
        goalPublisher?.publish(message)
        print(message.data as Any)
        
        // console log
        consoleLogTextView.text = consoleLogTextView.text +  "\ngoto : ( \(xTextField.text ?? "0") , \(yTextField.text ?? "0") )"
        usleep(useconds_t(0.1*second))
        consoleLogTextView.scrollRangeToVisible(NSMakeRange(consoleLogTextView.text.count-1, 1))
    }
    
    @IBAction func onCloseParticleButton(_ sender: Any) {
        let message = StringMessage()
        message.data = "Close Particle"
        systemPublisher?.publish(message)
        print(message.data as Any)
        
        // console log
        consoleLogTextView.text = consoleLogTextView.text +  "\n" + message.data!
        usleep(useconds_t(0.1*second))
        consoleLogTextView.scrollRangeToVisible(NSMakeRange(consoleLogTextView.text.count-1, 1))
    }
    
    @IBAction func onOpenParticleButton(_ sender: Any) {
        let message = StringMessage()
        message.data = "Open Particle"
        systemPublisher?.publish(message)
        print(message.data as Any)
        
        // console log
        consoleLogTextView.text = consoleLogTextView.text +  "\n" + message.data!
        usleep(useconds_t(0.1*second))
        consoleLogTextView.scrollRangeToVisible(NSMakeRange(consoleLogTextView.text.count-1, 1))
    }
    
    @IBAction func onRestOdomButton(_ sender: Any) {
        let message = StringMessage()
        message.data = "Reset Odom"
        systemPublisher?.publish(message)
        print(message.data as Any)
        
        // console log
        consoleLogTextView.text = consoleLogTextView.text +  "\n" + message.data!
        usleep(useconds_t(0.1*second))
        consoleLogTextView.scrollRangeToVisible(NSMakeRange(consoleLogTextView.text.count-1, 1))
    }
    
    @IBAction func onClearLidarButton(_ sender: Any) {
        let message = StringMessage()
        message.data = "Clear Lidar"
        systemPublisher?.publish(message)
        print(message.data as Any)
        
        // console log
        consoleLogTextView.text = consoleLogTextView.text +  "\n" + message.data!
        usleep(useconds_t(0.1*second))
        consoleLogTextView.scrollRangeToVisible(NSMakeRange(consoleLogTextView.text.count-1, 1))
    }
    
    @objc func onBackButton() {
        // back to firstview
       dismiss(animated: true, completion: nil)
    }
    
    
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
