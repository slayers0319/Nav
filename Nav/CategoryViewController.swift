//
//  CategoryViewController.swift
//  Nav
//
//  Created by 賴奕翔 on 2021/2/2.
//

import UIKit
import RBSManager

class CategoryViewController: UIViewController, RBSManagerDelegate {
    // MARK: - Declare
    @IBOutlet var ToolbarCategory: UIToolbar!
    @IBOutlet var ConnectButtonCategory: UIButton!
    
    @IBOutlet var CoffeeButton: UIButton!
    @IBOutlet var MilkButton: UIButton!
    @IBOutlet var WeedButton: UIButton!
    @IBOutlet var SnackButton: UIButton!
    
    // Navgation bar
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
        
        // MARK: - Button setting
        CoffeeButton.layer.borderWidth = 2/UIScreen.main.nativeScale
        CoffeeButton.layer.borderColor = UIColor.black.cgColor
        MilkButton.layer.borderWidth = 2/UIScreen.main.nativeScale
        MilkButton.layer.borderColor = UIColor.black.cgColor
        WeedButton.layer.borderWidth = 2/UIScreen.main.nativeScale
        WeedButton.layer.borderColor = UIColor.black.cgColor
        SnackButton.layer.borderWidth = 2/UIScreen.main.nativeScale
        SnackButton.layer.borderColor = UIColor.black.cgColor
        
        CoffeeButton.imageView?.contentMode = .scaleAspectFit
        MilkButton.imageView?.contentMode = .scaleAspectFit
        WeedButton.imageView?.contentMode = .scaleAspectFit
        SnackButton.imageView?.contentMode = .scaleAspectFit
        
        CoffeeButton.setTitle(" 咖啡豆", for: .normal)
        MilkButton.setTitle(" 乳製品", for: .normal)
        WeedButton.setTitle("  茶葉", for: .normal)
        SnackButton.setTitle("  禮盒", for: .normal)
        
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Socket setting
    func loadSettings() {
        let defaults = UserDefaults.standard
        socketHost = defaults.string(forKey: "socket_host")
    }
    
    func saveSettings() {
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
    //------------manager-----------------------
    
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
    @IBAction func onConnectButtonCategory(_ sender: Any) {
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
        CoffeeButton.isEnabled = connected
        MilkButton.isEnabled = connected
        WeedButton.isEnabled = connected
        SnackButton.isEnabled = connected
        
        CoffeeButton.alpha = CoffeeButton.isEnabled ? 1 : 0.4
        MilkButton.alpha = MilkButton.isEnabled ? 1 : 0.4
        WeedButton.alpha = WeedButton.isEnabled ? 1 : 0.4
        SnackButton.alpha = SnackButton.isEnabled ? 1 : 0.4
        
        if connected {
            let redColor = UIColor(red: 0.729, green: 0.131, blue: 0.144, alpha: 1.0)
            ConnectButtonCategory.backgroundColor = redColor
            ConnectButtonCategory.setTitle("DISCONNECT", for: .normal)
        } else {
            let greenColor = UIColor(red: 0.329, green: 0.729, blue: 0.273, alpha: 1.0)
            ConnectButtonCategory.backgroundColor = greenColor
            ConnectButtonCategory.setTitle("CONNECT", for: .normal)
        }
    }
    
    func updateToolbarItems() {
        if turtleManager?.connected == true {
            ToolbarCategory.setItems([stopButton!], animated: false)
        } else {
            ToolbarCategory.setItems([backButton!,flexibleToolbarSpace!, hostButton!], animated: false)
        }
    }
    
    
    // MARK: - Button activative
    
    @IBAction func onCoffeeButton(_ sender: Any) {
        let message = StringMessage()
        message.data = "Destnation A"
        turtlePublisher?.publish(message)
    }
    
    @IBAction func onMilkButton(_ sender: Any) {
        let message = StringMessage()
        message.data = "Destnation B"
        turtlePublisher?.publish(message)
    }
    
    @IBAction func onTeaButton(_ sender: Any) {
        let message = StringMessage()
        message.data = "Destnation C"
        turtlePublisher?.publish(message)
    }
    
    @IBAction func onGiftButton(_ sender: Any) {
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
       dismiss(animated: true, completion: nil)
    }
}
