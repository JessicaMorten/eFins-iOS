//
//  EFinsTabBarController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/15/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit

class EFinsTabBarController: UITabBarController {

    var currentPatrolPrompt:CurrentPatrolViewController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if var viewControllers = self.viewControllers {
            if let controller = viewControllers[1] as? CurrentPatrolViewController {
                self.currentPatrolPrompt = controller
            }
            println("map")
            if let mapController = UIStoryboard(name: "Map", bundle: nil).instantiateInitialViewController() as? UINavigationController {
                println(mapController)
                let icon = UITabBarItem(title: "Map", image:UIImage(named: "map_route"), selectedImage: nil)
                mapController.tabBarItem = icon
                viewControllers.insert(mapController, atIndex: 2)
                self.viewControllers = viewControllers
            }
        }
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startNewPatrol() {
        self.selectedIndex = 0
        if var controllers = self.viewControllers {
            controllers.removeAtIndex(1)
            if let controller = UIStoryboard(name: "PatrolLog", bundle: nil).instantiateInitialViewController() as? UISplitViewController {
                let icon1 = UITabBarItem(title: "Patrol", image:UIImage(named: "shield"), selectedImage: nil)
                controller.tabBarItem = icon1
                controllers.insert(controller, atIndex: 1)
                self.viewControllers = controllers
                self.selectedIndex = 1
            }
        }
    }
    
    func hidePatrol(animateSave:Bool?) {
        self.selectedIndex = 0
        if var controllers = self.viewControllers {
            controllers.removeAtIndex(1)
            if let controller = currentPatrolPrompt {
                controllers.insert(controller, atIndex: 1)
                self.viewControllers = controllers
                self.selectedIndex = 1
                if animateSave == true {
                    controller.animateSave()
                }
            }
        }
    }
    
    func isDisplayingEditablePatrol() -> Bool {
        if var controllers = self.viewControllers {
            if let controller = controllers[1] as? CurrentPatrolViewController {
                return false
            } else {
                if let controller = ((controllers[1] as? PatrolLogSplitViewController)?.viewControllers[0] as? UINavigationController)?.viewControllers[0] as? PatrolLogSidebarTableViewController {
                    return controller.allowEditing
                } else {
                    return false
                }
            }
        } else {
            return false
        }
    }
    
    func displayPatrol(patrol:PatrolLog, returnToLogbook:Bool=false) {
        self.selectedIndex = 0
        if var controllers = self.viewControllers {
            controllers.removeAtIndex(1)
            if let controller = UIStoryboard(name: "PatrolLog", bundle: nil).instantiateInitialViewController() as? UISplitViewController {
                let icon1 = UITabBarItem(title: "Patrol", image:UIImage(named: "shield"), selectedImage: nil)
                controller.tabBarItem = icon1
                controllers.insert(controller, atIndex: 1)
                self.viewControllers = controllers
                if let controller = (controller.viewControllers[0] as? UINavigationController)?.viewControllers[0] as? PatrolLogSidebarTableViewController {
                    controller.patrolLog = patrol
                    controller.isNew = false
                    controller.allowEditing = false
                    controller.returnToLogbook = returnToLogbook
                }
                if self.selectedIndex == 0 {
                    // animate
                    let fromView = self.viewControllers![0] as! UIViewController
                    let toView = self.viewControllers![1] as! UIViewController
                    UIView.transitionFromView(fromView.view, toView: toView.view, duration: NSTimeInterval(0.3), options: UIViewAnimationOptions.TransitionCurlUp, completion: { (done) in
                        self.selectedIndex = 1
                    })
                } else {
                    self.selectedIndex = 1
                }
            }
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
