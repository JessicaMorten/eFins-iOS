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

class RegistrationIncompleteViewController: UIViewController {
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var registerButton: MKButton!
    var email:String?
    var password:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBlur()
        let defaults = NSUserDefaults.standardUserDefaults()
        var state = "NoAccount"
        if let storedState = defaults.stringForKey("SessionState") {
            state = storedState
        }
        switch state {
            case "Authenticated":
                println("Authenticated")
            case "NotApproved":
                println("NotApproved")
            case "EmailNotConfirmed":
                println("EmailNotConfirmed")
            default:
                var replacementHeader = NSMutableAttributedString(attributedString: self.headerLabel.attributedText)
                replacementHeader.mutableString.replaceOccurrencesOfString("<email>", withString: self.email!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: NSMakeRange(0, replacementHeader.mutableString.length))
                self.headerLabel.attributedText = replacementHeader
        }
        
    }

    func applyBlur() {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
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

    @IBAction func goBackAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func registerAction(sender: AnyObject) {
        let params = [
            "email": self.email!,
            "password": self.password!
        ]
        Alamofire.request(.POST, Urls.register, parameters: params)
            .responseString { (request, response, data, error) in
            println(response)
            println(data)
        }
    }
}
