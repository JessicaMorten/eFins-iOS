 //
//  AppDelegate.swift
//  eFins
//
//  Created by CHAD BURT on 3/5/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import semver
import Alamofire
import SwiftyJSON
import Raven
 
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var lastCheckedForUpdates:NSDate?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        RavenClient.clientWithDSN(SENTRY_DSN)
        RavenClient.sharedClient?.setupExceptionHandler()
        RavenClient.sharedClient?.captureMessage("Launched app")

        let defaults = NSUserDefaults.standardUserDefaults()
        if ((defaults.objectForKey("SessionToken")) != nil)
        {
            self.gotoMainStoryboard()
        } else {
            self.showLogin()
        }
        
        DataSync.manager.start()
        return true
    }
    
    func showLogin() {
        let storyboard:UIStoryboard = UIStoryboard(name: "Login", bundle: NSBundle(identifier: "mainBundle"))
        var viewController = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
        self.window?.rootViewController = viewController
    }
    
    func signOut() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.removeObjectForKey("SessionToken")
        defaults.removeObjectForKey("SessionState")
        defaults.removeObjectForKey("UserEmail")
        self.showLogin()
        
    }
    
    func getUser() -> User? {
        let defaults = NSUserDefaults.standardUserDefaults()
        if let email = defaults.objectForKey("UserEmail") as? String {
            let params = NSPredicate(format: "email = %@",  email)
            let results = User.objectsWithPredicate(params)
            if results.count > 0 {
                return results.objectAtIndex(UInt(0)) as? User
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    func gotoMainStoryboard() {
        let storyboard:UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle(identifier: "mainBundle"))
        var viewController = storyboard.instantiateViewControllerWithIdentifier("MainTabs") as! UITabBarController
        self.window?.rootViewController = viewController
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        checkIfUpToDate()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func checkIfUpToDate() {
        if let lastChecked = self.lastCheckedForUpdates {
            let minutes = NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitMinute, fromDate: lastChecked, toDate: NSDate(), options: nil).minute
            if minutes < 10 {
                return
            }
        }
        self.lastCheckedForUpdates = NSDate()
        if let version = NSBundle.applicationVersionNumber {
            if Semver.valid(version) {
                println("eFins Version \(version)")
                Alamofire.request(.GET, "https://www.installrapp.com/apps/status/oEuTK6AjDhQnw3Ez4hQfNZo3AOxG.json")
                    .responseJSON { (_, _, data, _) in
                        var json = JSON(data!)
                        if let installrVersion = json["appData"]["versionNumber"].string {
                            if let installLink = json["appData"]["installUrl"].string {
                                println("Installr version = \(installrVersion)")
                                if Semver.gt(installrVersion, version2: version) {
                                    println("out of date!")
                                    let alertController = UIAlertController(title: "Updates Available", message:
                                        "There is a new version of eFins available. Please upgrade as soon as convenient", preferredStyle: UIAlertControllerStyle.Alert)
                                    alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel,handler: nil))
                                    alertController.addAction(UIAlertAction(title: "Update", style: UIAlertActionStyle.Default,handler: { (action) in
                                            let url = NSURL(string: installLink)
                                            UIApplication.sharedApplication().openURL(url!)
                                    }))
                                    if let root = self.window?.rootViewController {
                                        if root.isViewLoaded() && root.view.window != nil {
                                            root.presentViewController(alertController, animated: true, completion: nil)
                                        }
                                    }
                                }
                            }
                        }
                }
            }
        }
    }


}

