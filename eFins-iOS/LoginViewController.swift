//
//  LoginViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/5/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import MaterialKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var emailTextField: MKTextField!
    @IBOutlet weak var passwordTextField: MKTextField!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var createdByLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let borderColor = UIColor(hex: 000, alpha: 0.2)
        self.signInButton.layer.borderColor = borderColor.CGColor
        self.signInButton.layer.borderWidth = 2.0
        self.signInButton.layer.cornerRadius = 5.0
        self.signInButton.layer.masksToBounds = true;
        
        self.applyBlur()
        
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
    
    func applyBlur() {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds //view is self.view in a UIViewController
        //            blurEffectView.alpha = 0.9;
        self.view.insertSubview(blurEffectView, aboveSubview: self.backgroundImageView);
        
        //if you have more UIViews on screen, use insertSubview:belowSubview: to place it underneath the lowest view
        
        //add auto layout constraints so that the blur fills the screen upon rotating device
        blurEffectView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))

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
        if (self.emailTextField.text != nil && !self.emailTextField.text.isEmpty &&
            self.passwordTextField.text != nil && !self.passwordTextField.text.isEmpty) {
                self.instructionLabel.hidden = true;
                self.signInButton.hidden = false;
        } else {
            self.instructionLabel.hidden = false;
            self.signInButton.hidden = true;
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) {
        if (textField == self.emailTextField) {
            self.passwordTextField.becomeFirstResponder()
        } else if (textField == self.passwordTextField) {
            self.login(self)
        }
    }

    @IBAction func login(sender: AnyObject) {
        if (validateEmail(self.emailTextField.text)) {
            if (true) {
                self.performSegueWithIdentifier("registrationIncomplete", sender: self)
            } else {
                // proceed to main application
            }
        } else {
            self.emailTextField.becomeFirstResponder()
            var alert = UIAlertController(title: "Login Error", message: "You must enter a valid email", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler:{ (ACTION :UIAlertAction!)in
                println("Okay, I see that my email is messed up.")                
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func validateEmail(email: String) -> Bool {
        if let match = email.rangeOfString("[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}", options: .RegularExpressionSearch) {
            return true
        } else {
            return false
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
