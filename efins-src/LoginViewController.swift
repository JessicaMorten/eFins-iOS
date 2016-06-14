//
//  LoginViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/5/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import MaterialKit
import Alamofire
import SwiftyJSON

let TokenObtainedNotification = "TokenObtainedNotification"

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var emailTextField: MKTextField!
    @IBOutlet weak var passwordTextField: MKTextField!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var createdByLabel: UILabel!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let borderColor = UIColor(white: 000, alpha: 0.2)
        self.signInButton.layer.borderColor = borderColor.CGColor
        self.signInButton.layer.borderWidth = 2.0
        self.signInButton.layer.cornerRadius = 5.0
        self.signInButton.layer.masksToBounds = true;
        
        
        self.emailTextField.layer.borderWidth = CGFloat(0.0)
        self.emailTextField.placeholder = "email address"
        self.passwordTextField.layer.borderWidth = CGFloat(0.0)
        self.passwordTextField.placeholder = "password"
        self.emailTextField.floatingPlaceholderEnabled = true

        // Do any additional setup after loading the view.
//        NSNotificationCenter.defaultCenter().addObserver(self,
//            selector: "keyboardDidShow", name: UIKeyboardDidShowNotification, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self,
//            selector: "keyboardWillHide", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.clearForm()
    }
    
    @IBAction func usernameEditingChanged(sender: MKTextField) {
        self.formValuesChanged()
    }

    @IBAction func passwordEditingChanged(sender: MKTextField) {
        self.formValuesChanged()
    }
    
    func keyboardDidShow() {
        // eventually, move self.createdByLabel up when keyboard is shown
    }
    
    func keyboardWillHide() {
        
    }
    
    func formValuesChanged() {
        if (self.emailTextField.text != nil && !self.emailTextField.text!.isEmpty &&
            self.passwordTextField.text != nil && !self.passwordTextField.text!.isEmpty) {
                self.instructionLabel.hidden = true;
                self.signInButton.hidden = false;
        } else {
            self.instructionLabel.hidden = false;
            self.signInButton.hidden = true;
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == self.emailTextField) {
            self.passwordTextField.becomeFirstResponder()
        } else if (textField == self.passwordTextField) {
            self.login(self)
        }
        return true
    }

    @IBAction func login(sender: AnyObject) {
        if (validateEmail(self.emailTextField.text!)) {
            let params = [
                "email": self.emailTextField.text!,
                "password": self.passwordTextField.text!
            ]
            print("Posting to \(Urls.getToken)")
            let defaults = NSUserDefaults.standardUserDefaults()
            Alamofire.request(.POST, Urls.getToken, parameters: params)
                .responseString { response in
                    //print(data)
                    if (response.result.error != nil) {
                        self.alert("Login Error", message: "Problem connecting to server \(response.result.error)")
                    } else if (response.response?.statusCode == 404) {
                        print("User not registered")
                        defaults.setValue("NoAccount", forKey: "SessionState")
                        self.performSegueWithIdentifier("registrationIncomplete", sender: self)
                    } else if (response.response?.statusCode == 401) {
                        self.passwordTextField.becomeFirstResponder()
                        self.alert("Login Error", message: "Invalid password")
                        self.forgotPasswordButton.hidden = false
                    } else if (response.response?.statusCode == 403) {
                        if ((response.result.value!.rangeOfString("approved")) != nil) {
                            print("account not approved")
                            defaults.setValue("NotApproved", forKey: "SessionState")
                        } else {
                            defaults.setValue("EmailNotConfirmed", forKey: "SessionState")
                            print("email not confirmed")
                        }
                        defaults.setValue(self.emailTextField.text, forKey: "UserEmail")
                        self.performSegueWithIdentifier("registrationIncomplete", sender: self)
                        self.alert("Login Error", message: "Invalid password")
                    } else if response.response?.statusCode == 200 {
                        print("Authenticated!")
                        let json = JSON(data: response.result.value!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
                        if let token = json["token"].string{
                            print("Token is \(token)")
                            defaults.setValue(token, forKey: "SessionToken")
                            defaults.setValue(params["email"], forKey: "UserEmail")
                            defaults.setValue("Authenticated", forKey: "SessionState")
                            self.alert("Account Approved", message: "You may now access the system")
                            NSNotificationCenter.defaultCenter().postNotificationName(TokenObtainedNotification, object: self)
                            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                            appDelegate.gotoMainStoryboard()
                        }
                    } else {
                        print(response.result.value!)
                        self.alert("Login Error", message: "Unknown error attempting login")
                    }
                }
        } else {
            self.emailTextField.becomeFirstResponder()
            self.alert("Login Error", message: "You must enter a valid email")
        }
    }
    
    @IBAction func forgotPasswordAction(sender: AnyObject) {
        let params = [
            "email": self.emailTextField.text!,
        ]
        Alamofire.request(.POST, Urls.passwordReset, parameters: params)
            .responseString { (response) in
                print(response)
        }
        self.alert("Password Reset", message: "An email has been sent with instructions on how to reset your password")
        self.forgotPasswordButton.hidden = true
    }
    
    func alert(title:String, message:String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler:{ (ACTION :UIAlertAction)in
            print("Okay, I see that my email is messed up.")
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func validateEmail(email: String) -> Bool {
        if let match = email.rangeOfString("[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: .RegularExpressionSearch) {
            return true
        } else {
            return false
        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "registrationIncomplete") {
            var controller:RegistrationIncompleteViewController = segue.destinationViewController as! RegistrationIncompleteViewController
            controller.password = self.passwordTextField.text
            controller.email = self.emailTextField.text
        }
    }
    
    func clearForm() {
        self.passwordTextField.text = ""
        self.emailTextField.text = ""
        formValuesChanged()
    }
    
}
