//
//  CurrentPatrolViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/15/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit

class CurrentPatrolViewController: UIViewController {

    @IBOutlet weak var startPatrolButton: UIButton!
    @IBOutlet weak var savedLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let borderColor = UIColor.whiteColor()
        self.startPatrolButton.layer.borderColor = borderColor.CGColor
        self.startPatrolButton.layer.borderWidth = 2.0
        self.startPatrolButton.layer.cornerRadius = 5.0
        self.startPatrolButton.layer.masksToBounds = true;
        self.savedLabel.layer.borderWidth = 2.0
        self.savedLabel.layer.cornerRadius = 5.0
        self.savedLabel.layer.borderColor = self.savedLabel.backgroundColor?.CGColor
        self.savedLabel.layer.masksToBounds = true;
        self.savedLabel.alpha = 0.0
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startPatrolLog(sender: AnyObject) {
        print("start patrol log")
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.titleLabel.alpha = 0.0
            self.descriptionLabel.alpha = 0.0
            self.startPatrolButton.alpha = 0.0
            self.backgroundImage.alpha = 0.8
            
            }, completion: {
                (finished: Bool) -> Void in
                if let tabBarController = self.tabBarController as? EFinsTabBarController {
                    tabBarController.startNewPatrol()
                    self.titleLabel.alpha = 1.0
                    self.descriptionLabel.alpha = 1.0
                    self.startPatrolButton.alpha = 1.0
                    self.backgroundImage.alpha = 1.0
                }
        })
    }
    
    func animateSave() {
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
            self.savedLabel.alpha = 1.0
            }, completion: {
                (finished: Bool) -> Void in
                
                UIView.animateWithDuration(1.0, delay: 2.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                    self.savedLabel.alpha = 0.0
                    }, completion: nil)
        })
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
