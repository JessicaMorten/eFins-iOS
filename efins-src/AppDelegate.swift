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
 import Realm
 import RavenSwift
 import Teleport_NSLog
 import AWSS3
 
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var lastCheckedForUpdates:NSDate?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        RavenClient.clientWithDSN(SENTRY_DSN)
        RavenClient.sharedClient?.setupExceptionHandler()
        RavenClient.sharedClient?.captureMessage("Launched app")
        
        //TELEPORT_DEBUG = true
        Teleport.startWithForwarder(EfinsLoggingHttpForwarder(aggregatorUrl: SERVER_ROOT + "clientlog"))
        
        
        let credentialsProvider = AWSStaticCredentialsProvider(accessKey: "AKIAIIJEMWNG5Z4PM4TA", secretKey: "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")
        let configuration = AWSServiceConfiguration(
            region: AWSRegionType.USWest2,
            credentialsProvider: credentialsProvider)
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        // Inside your application(application:didFinishLaunchingWithOptions:)
        
        // Notice setSchemaVersion is set to 1, this is always set manually. It must be
        // higher than the previous version (oldSchemaVersion) or an RLMException is thrown
        let rconfig = RLMRealmConfiguration.defaultConfiguration()
        rconfig.schemaVersion = 5
        rconfig.migrationBlock = { (migration:RLMMigration, oldSchemaVersion:UInt64) in
            
            // We haven’t migrated anything yet, so oldSchemaVersion == 0
            if oldSchemaVersion < 1 {
                // Nothing to do!
                // Realm will automatically detect new properties and removed properties
                // And will update the schema on disk automatically
                
                
                //                [migration enumerateObjects:Person.className
                //                    block:^(RLMObject *oldObject, RLMObject *newObject) {
                //
                //                    // combine name fields into a single field
                //                    newObject[@"fullName"] = [NSString stringWithFormat:@"%@ %@",
                //                    oldObject[@"firstName"],
                //                    oldObject[@"lastName"]];
                //                    }];
            }
            
            if oldSchemaVersion < 2 {
                // do nothing
                migration.enumerateObjects(Photo.className(), block: { (oldObject:RLMObject?, newObject:RLMObject?) in
                    if let photo = newObject as? Photo {
                        photo.createSignedUrls { (success:Bool) in
                            if !success {
                                print("Could not create signed url for photo")
                            }
                        }
                    }
                })
            }
            
            if oldSchemaVersion < 3 {
                migration.enumerateObjects(Photo.className(), block: { (oldObject:RLMObject?, newObject:RLMObject?) in
                    if let photo = newObject as? Photo {
                        photo.bucket = PHOTOS_BUCKET
                        photo.s3key = photo.localId
                    }
                })
            }

            if oldSchemaVersion < 4 {
                migration.enumerateObjects(Photo.className(), block: { (oldObject:RLMObject?, newObject:RLMObject?) in
                    if let photo = newObject as? Photo {
                        if let oldPhoto = oldObject as? Photo {
                            photo.uploadedThumbnail = oldPhoto.uploaded
                        }
                    }
                })
            }
            
            if oldSchemaVersion < 5 {
                // added deletedAt attribute to EFinsModel
                migration.enumerateObjects(EfinsModel.className(), block: { (oldObject:RLMObject?, newObject:RLMObject?) in
                    if let efo = newObject as? EfinsModel {
                        efo.deletedAt = NSDate(timeIntervalSinceNow: 0)
                    }
                })

            }
        }
    
        RLMRealmConfiguration.setDefaultConfiguration(rconfig)
        
        var i = UInt(0)
        let photos = Photo.objectsWhere("uploaded = false", [])
        RLMRealm.defaultRealm().beginWriteTransaction()
        while i < photos.count {
            if let photo = photos.objectAtIndex(i) as? Photo {
                photo.createSignedUrls { (success:Bool) in
                    print("Signed")
                }
                photo.dirty = true
            }
            i++
        }
        try! RLMRealm.defaultRealm().commitWriteTransaction()
        // now that we have called `setSchemaVersion(_:_:_:)`, opening an outdated
        // Realm will automatically perform the migration and opening the Realm will succeed
        // i.e. Realm()
        
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
        let viewController = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
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
        let viewController = storyboard.instantiateViewControllerWithIdentifier("MainTabs") as! UITabBarController
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
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    


}

