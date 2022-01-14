//
//  NavViewController.swift
//  Nav
//
//  Created by 賴奕翔 on 2021/2/2.
//
//

import UIKit
import RBSManager

class NavViewController: UIViewController, RBSManagerDelegate {
    // MARK: - Declare
    // user interface
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var connectButton: UIButton!
    @IBOutlet var DestAButton: UIButton!
    @IBOutlet var DestBButton: UIButton!
    @IBOutlet var DestCButton: UIButton!
    @IBOutlet var DestDButton: UIButton!
    
    var backButton: UIBarButtonItem?
    var hostButton: UIBarButtonItem?
    var stopButton: UIBarButtonItem?
    var flexibleToolbarSpace: UIBarButtonItem?

    // RBSManager
    var turtleManager: RBSManager?
    var turtlePublisher: RBSPublisher?
    var stopPublisher: RBSPublisher?
    
    // user settings
    var socketHost: String?

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
        turtlePublisher = turtleManager?.addPublisher(topic: "/Destnation", messageType: "std_msgs/String", messageClass: StringMessage.self)
        stopPublisher = turtleManager?.addPublisher(topic: "/stop", messageType: "std_msgs/String", messageClass: StringMessage.self)
        
        DestAButton.layer.borderWidth = 2/UIScreen.main.nativeScale
        DestAButton.layer.borderColor = UIColor.systemBlue.cgColor
        DestBButton.layer.borderWidth = 2/UIScreen.main.nativeScale
        DestBButton.layer.borderColor = UIColor.systemBlue.cgColor
        DestCButton.layer.borderWidth = 2/UIScreen.main.nativeScale
        DestCButton.layer.borderColor = UIColor.systemBlue.cgColor
        DestDButton.layer.borderWidth = 2/UIScreen.main.nativeScale
        DestDButton.layer.borderColor = UIColor.systemBlue.cgColor
        
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
        DestAButton.isEnabled = connected
        DestBButton.isEnabled = connected
        DestCButton.isEnabled = connected
        DestDButton.isEnabled = connected
        
        DestAButton.alpha = DestAButton.isEnabled ? 1 : 0.4
        DestBButton.alpha = DestBButton.isEnabled ? 1 : 0.4
        DestCButton.alpha = DestCButton.isEnabled ? 1 : 0.4
        DestDButton.alpha = DestDButton.isEnabled ? 1 : 0.4
        
        if connected {
            let redColor = UIColor(red: 0.729, green: 0.131, blue: 0.144, alpha: 1.0)
            connectButton.backgroundColor = redColor
            connectButton.setTitle("DISCONNECT", for: .normal)
        } else {
            let greenColor = UIColor(red: 0.329, green: 0.729, blue: 0.273, alpha: 1.0)
            connectButton.backgroundColor = greenColor
            connectButton.setTitle("CONNECT", for: .normal)
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
    @IBAction func onDestnationAButton(_ sender: Any) {
        let message = StringMessage()
        message.data = "Destnation A"
        turtlePublisher?.publish(message)
    }
    
    @IBAction func onDestnationBButton(_ sender: Any) {
        let message = StringMessage()
        message.data = "Destnation B"
        turtlePublisher?.publish(message)
    }
    
    @IBAction func onDestnationCButton(_ sender: Any) {
        let message = StringMessage()
        message.data = "Destnation C"
        turtlePublisher?.publish(message)
    }
    
    @IBAction func onDestnationDButton(_ sender: Any) {
        let message = StringMessage()
        message.data = "Destnation D"
        turtlePublisher?.publish(message)
    }
    
    @objc func onStopButton() {
        let message = StringMessage()
        message.data = "stop"
        stopPublisher?.publish(message)
    }
    
    @objc func onBackButton() {
        // back to firstview
       dismiss(animated: true, completion: nil)
    }
    
    
}
