//
//  dataSyncManager.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Alamofire
import Realm
import SwiftyJSON

private let _mgr = DataSync()

class DataSync {
    
    let periodicSynchronizationInterval : NSTimeInterval = 30.0 //Seconds
    let reachability: Reachability
    var timer: NSTimer = NSTimer()
    var syncInProgress = false
    
    
    init() {
        let uri = NSURL(string: SERVER_ROOT)
        let host = uri?.host ?? ""
        self.reachability = Reachability(hostname: host)
        self.log("Reachability will be measured against " + host)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged", name: ReachabilityChangedNotification, object: reachability)
        reachability.startNotifier()
    }
    
    class var manager: DataSync {
        return _mgr
    }
    
    func sync() {
        self.log("Begin Synchronization")
        if ( self.syncInProgress ) {
            self.log("Synchronization already in progress; yielding.")
            return
        }
        let prio = DISPATCH_QUEUE_PRIORITY_DEFAULT
        let queue = dispatch_get_global_queue(prio, 0)
        self.syncInProgress = true
        dispatch_async(queue) {
            self.log("Sync executing on background queue")
            
            let defaults = NSUserDefaults.standardUserDefaults()
            let usn = defaults.integerForKey("currentUsn")
            let endOfLastSync = defaults.integerForKey("endOfLastSync")
            
            self.pull( usn, endOfLastSync: endOfLastSync, maxCount: 0)
            
            
            let dRealm = self.defaultRealm()
            dRealm.beginWriteTransaction()
            
            dRealm.commitWriteTransaction()
            dispatch_async(dispatch_get_main_queue()) {
                //Emit UI update event here if needed?
                self.syncInProgress = false
                self.log("Synchronization complete.")
            }
        }
    }
    
    @objc func syncFire(ti: NSTimer) {
        self.sync()
    }
    
    func defaultRealm() -> RLMRealm {
        return RLMRealm.defaultRealm()
    }
    
    func start() {
        self.log("DataSync Manager Starting");
        let dRealm = self.defaultRealm()
        self.log("Default Realm file is: " + dRealm.path)
        self.log("Checking reachability against " + SERVER_ROOT);
        if (self.reachability.isReachable()) {
            self.log("Server " + SERVER_ROOT + " is currently reachable")
            let token = NSUserDefaults.standardUserDefaults().stringForKey("SessionToken")
            if (token != nil) {
                //If connectivity and a token, trigger a sync now.
                self.log("Found a SessionToken: \(token)")
                self.sync()
            }
            self.startPeriodicSyncs()
        } else {
            self.log("Server " + SERVER_ROOT + " is NOT currently reachable")
        }
    }
    
    func startPeriodicSyncs() {
        self.log("Starting periodic synchronization")
        self.timer = NSTimer.scheduledTimerWithTimeInterval(self.periodicSynchronizationInterval, target: self, selector:"syncFire:", userInfo: nil, repeats: true)

    }
    
    func stopPeriodicSyncs() {
        self.log("Stopping periodic synchronization")
        self.timer.invalidate()
    }
    
    @objc func reachabilityChanged() {
        if (self.reachability.isReachable()) {
            self.log("Server became reachable")
            self.startPeriodicSyncs()
        } else {
            self.log("Server became unreachable")
            self.stopPeriodicSyncs()
        }
    }
    
    func log(msg: String) {
        NSLog("DataSync Manager: " + msg)
    }
    
    func pull(currentUsn: Int, endOfLastSync: Int, maxCount: Int ) {
        let params = [
            "afterUsn": currentUsn,
            "endOfLastSync": endOfLastSync,
            "maxCount": maxCount
        ]
        self.log("Posting to \(Urls.sync)")
        Alamofire.request(.POST, Urls.sync, parameters: params)
            .responseString { (request, response, data, error) in
                println(data)
                if (error != nil) {
                    self.log("Connection Error, Problem connecting to server")
                } else if (response?.statusCode == 404) {
                    self.log("404")
                } else if (response?.statusCode == 401) {
                    self.log("401")
                } else if (response?.statusCode == 403) {
                    self.log("403")
                } else if response?.statusCode == 200 {
                    self.log("Got reply to sync request")
                    let json = JSON(data: data!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
                    self.log(json.stringValue)
                } else {
                    self.log(data?.stringByStandardizingPath ?? "")
                }
        }

        
        
    }
    
    func push() {
        
    }
    
}
