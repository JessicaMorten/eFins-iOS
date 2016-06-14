//
//  RegistrationIncompleteViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import MaterialKit
import Alamofire
import SwiftyJSON

class RegistrationIncompleteViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var registerButton: MKButton!
    @IBOutlet weak var backButton: MKButton!
    @IBOutlet weak var nameField: MKTextField!
    @IBOutlet weak var networkActivityLabel: UILabel!
    @IBOutlet weak var networkActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var statusImage: UIImageView!
    
    
    let approvalInstructions = "This process should take less than 24 hours, and is to ensure the confidentiality of data in the system. On approval you will recieve instructions to confirm your email account, after which your account will be activated."
    let emailInstructions = "An email has been sent with instructions for verifying your account. If you do not see this email, please check your spam folder or contact \(ADMIN_EMAIL) for assistance."
    
    var email:String?
    var password:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nameField.layer.borderWidth = CGFloat(0.0)
        self.nameField.tintColor = UIColor.whiteColor()
        self.nameField.floatingLabelTextColor = UIColor.whiteColor()
        self.nameField.floatingPlaceholderEnabled = true
        self.nameField.textColor = UIColor.whiteColor()
        self.nameField.attributedPlaceholder = NSAttributedString(string:"enter your full name",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        let defaults = NSUserDefaults.standardUserDefaults()
        var state = "NoAccount"
        if let storedState = defaults.stringForKey("SessionState") {
            state = storedState
        }
        prepareState(state)
    }
    
    func prepareState(state:String) {
        switch state {
            case "Authenticated":
                print("Authenticated")
            case "NotApproved":
                print("NotApproved")
                self.registerButton.hidden = true
                self.backButton.hidden = false
                self.nameField.hidden = true
                self.instructionsLabel.hidden = false
                self.instructionsLabel.text = approvalInstructions
                self.statusImage.image = UIImage(named: "approve")
                self.statusImage.hidden = false
            case "EmailNotConfirmed":
                print("EmailNotConfirmed")
                self.registerButton.hidden = true
                self.backButton.hidden = false
                self.nameField.hidden = true
                self.instructionsLabel.hidden = false
                self.statusImage.image = UIImage(named: "inbox")
                self.statusImage.hidden = false
                self.instructionsLabel.text = emailInstructions
            default:
                print("default")
                self.instructionsLabel.hidden = true
                self.statusImage.hidden = true
        }
        self.headerLabel.attributedText = self.getHeader(state)
        if state == "NotApproved" || state == "EmailNotConfirmed" {
            var delta: Int64 = 10 * Int64(NSEC_PER_SEC)
            var time = dispatch_time(DISPATCH_TIME_NOW, delta)
            
            dispatch_after(time, dispatch_get_main_queue(), {
                self.checkStatus()
            });
        }
    }
    
    func getHeader(state: String) -> NSAttributedString {
        let header = NSMutableAttributedString()
        if let font = UIFont(name: "HelveticaNeue-Light", size: 36) {
            if let italic = UIFont(name: "HelveticaNeue-LightItalic", size: 36) {
                let normalFont = [NSFontAttributeName:font]
                let italicFont = [NSFontAttributeName:italic]
                switch state {
                    case "NotApproved":
                        header.appendAttributedString(NSAttributedString(string: "The account for ", attributes: normalFont))
                        header.appendAttributedString(NSAttributedString(string: self.email!, attributes: italicFont))
                        header.appendAttributedString(NSAttributedString(string: " needs to be approved by an administrator", attributes: normalFont))
                    case "EmailNotConfirmed":
                        header.appendAttributedString(NSAttributedString(string: "The account for ", attributes: normalFont))
                        header.appendAttributedString(NSAttributedString(string: self.email!, attributes: italicFont))
                        header.appendAttributedString(NSAttributedString(string: " has been approved. Please check your email", attributes: normalFont))
                    default:
                        header.appendAttributedString(NSAttributedString(string: "The user ", attributes: normalFont))
                        header.appendAttributedString(NSAttributedString(string: self.email!, attributes: italicFont))
                        header.appendAttributedString(NSAttributedString(string: " does not exist", attributes: normalFont))
                }
            }
        }
        return header
    }

    @IBAction func goBackAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    @IBAction func registerAction(sender: AnyObject?) {
        print("Register Action")
        if (self.nameField.text == nil || self.nameField.text!.isEmpty) {
            alert("Form Error", message: "You must provide your full name to register", completion: nil)
        } else {
            self.nameField.hidden = true
            self.networkActivityIndicator.hidden = false
            self.networkActivityLabel.text = "Registering"
            self.networkActivityLabel.hidden = false
            self.networkActivityIndicator.startAnimating()
            let params = [
                "email": self.email!,
                "password": self.password!,
                "name": self.nameField.text!
            ]
            self.registerButton.hidden = true
            Alamofire.request(.POST, Urls.register, parameters: params)
                .responseString { response in
                    self.networkActivityLabel.hidden = true
                    self.networkActivityIndicator.hidden = true
                    if (response.result.error == nil) {
                        print("Status is \(response.response?.statusCode)")
                        print(response.result.value)
                        if response.response?.statusCode == 200 || response.response?.statusCode == 201 {
                            self.prepareState("NotApproved")
                        } else if response.response?.statusCode == 400 {
                            if ((response.result.value!.rangeOfString("name")) != nil) {
                                self.alert("Registration Error", message: "A user with this name is already registered. Could you be registered with another email address?", completion: {self.dismissViewControllerAnimated(true, completion: nil)})
                            } else {
                                let val = response.result.value!.rangeOfString("name")
                                print("It's unknown!!? \(val)")
                                self.alert("Registration Error", message: "An unknown validation error occurred registering", completion: {self.dismissViewControllerAnimated(true, completion: nil)})
                            }
                        } else {
                            self.alert("Registration Error", message: "An unknown error occurred registering", completion: {self.dismissViewControllerAnimated(true, completion: nil)})
                        }
                    } else {
                        print("There was an error")
                        print(response.result.error)
                        self.alert("Registration Error", message: "An unknown error occurred registering", completion: {self.dismissViewControllerAnimated(true, completion: nil)})
                        
                    }
            }
        }
    }
    
    func alert(title:String, message:String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler:{ (ACTION :UIAlertAction)in
            if completion != nil {
                completion!()
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func checkStatus() {
        print("CHeck status")
        let params = [
            "email": self.email!,
            "password": self.password!
        ]
        print("Posting to \(Urls.getToken)")
        let defaults = NSUserDefaults.standardUserDefaults()
        self.networkActivityLabel.text = "Checking Account Status"
        self.networkActivityLabel.hidden = false
        self.networkActivityIndicator.hidden = false
        var oldState = defaults.stringForKey("SessionState")
        if oldState == nil {
            oldState = "NotApproved"
        }
        Alamofire.request(.POST, Urls.getToken, parameters: params)
            .responseString { response in
                self.networkActivityLabel.hidden = true
                self.networkActivityIndicator.hidden = true
                if (response.result.error != nil) {
                    self.prepareState(oldState!)
                } else if (response.response?.statusCode == 404) {
                    self.alert("Error", message: "Users \(self.email) is not registered", completion: {self.dismissViewControllerAnimated(true, completion: nil)})
                    self.prepareState(oldState!)
                } else if (response.response?.statusCode == 401) {
                    self.alert("Error", message: "Password for \(self.email) was incorrect", completion: {self.dismissViewControllerAnimated(true, completion: nil)})
                } else if (response.response?.statusCode == 403) {
                    if ((response.result.value!.rangeOfString("approved")) != nil) {
                        defaults.setValue("NotApproved", forKey: "SessionState")
                        self.prepareState(defaults.objectForKey("SessionState") as! String)
                    } else {
                        defaults.setValue("EmailNotConfirmed", forKey: "SessionState")
                        self.prepareState(defaults.objectForKey("SessionState") as! String)
                    }
                } else if (response.response?.statusCode == 200) {
                    let json = JSON(data: response.result.value!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
                    if let token = json["token"].string{
                        defaults.setValue(token, forKey: "SessionToken")
                        defaults.setValue("Authenticated", forKey: "SessionState")
                        self.alert("Account Approved", message: "You may now access the system", completion: nil)
                        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                        appDelegate.gotoMainStoryboard()
                    } else {
                        self.alert("Login Error", message: "Problem reading response from server", completion: nil)
                        self.prepareState(oldState!)
                    }
                } else {
                    print(response.result.value!)
                    self.alert("Login Error", message: "Unknown error attempting login", completion: nil)
                    self.prepareState(oldState!)
                }
        }

    }

}
