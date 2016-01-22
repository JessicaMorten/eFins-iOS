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
import AWSS3

private let _mgr = DataSync()


@objc protocol DataSyncDelegate {
    optional func dataSyncDidStart()
    optional func dataSyncDidComplete(success: Bool)
    optional func dataSyncDidStartPull()
    optional func dataSyncDidStartPush()
    optional func dataSyncDidStartPhotos()
    optional func dataSyncUploadedPhotos(completed:Int, left:Int)
    optional func dataSyncPhotoUploadStarted(numPhotos:Int)
    optional func dataSyncPhotoUploadProgress(numPhotos:Int, numCompleted:Int)
    optional func dataSyncPhotoUploadCompleted(error:String?)
}

class DataSync: NSObject, NSURLSessionDelegate {
    
    let periodicSynchronizationInterval : NSTimeInterval = 300.0 // 5 minutes
    let reachability: Reachability
    var timer: NSTimer = NSTimer()
    var syncInProgress = false
    var syncEnabled = true
    var syncRealm: RLMRealm? = nil
    var syncQueue:Array<() -> ()> = []
    let syncCondition = NSCondition()
    var syncThread: NSThread? = nil
    var delegate:DataSyncDelegate?
    var uploadSession:NSURLSession?
    var numPhotosUploading = 0
    var numPhotosCompletedUploading = 0
    var numPhotosDownloading = 0
    var numPhotosCompletedDownloading = 0
    var downloadSession:NSURLSession?

    var lastSync:NSDate? {
        get {
            return NSUserDefaults.standardUserDefaults().objectForKey("lastSyncDate") as? NSDate
        }
        
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "lastSyncDate")
        }
    }
    
    override init() {
        let uri = NSURL(string: ServerRoot.address())
        let host = uri?.host ?? ""
        try! self.reachability = Reachability(hostname: host)
        super.init()
        self.log("Reachability will be measured against " + host)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reachabilityChanged", name: ReachabilityChangedNotification, object: reachability)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "tokenObtained", name: TokenObtainedNotification, object: nil)

        try! reachability.startNotifier()
        
        let sessionConfig = NSURLSessionConfiguration.backgroundSessionConfiguration("org.efins.eFins-iOS-Uploader")
            self.uploadSession = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
    }
    
    class var manager: DataSync {
        return _mgr
    }
    
    func sync() {
        if !self.syncEnabled {
            return
        }
        self.log("Begin Synchronization")
        if ( self.syncInProgress ) {
            self.log("Synchronization already in progress; yielding.")
            return
        }
        let token = NSUserDefaults.standardUserDefaults().stringForKey("SessionToken")
        if (token == nil) {
            self.log("Synchronization not yet possible; no session token; yielding.");
            return
        }
        self.syncInProgress = true
        self.delegate?.dataSyncDidStart?()
        
        self.queueThreadTask { () -> () in
            //self.log("Sync starting on background thread")
            let defaults = NSUserDefaults.standardUserDefaults()
            let usn = defaults.integerForKey("currentUsn")
            let endOfLastSync = defaults.integerForKey("endOfLastSync")
            self.syncRealm = RLMRealm.defaultRealm()
            self.log("Sync Realm file is: " + self.syncRealm!.path)
            //self.syncRealm!.beginWriteTransaction()
            dispatch_async(dispatch_get_main_queue(),{
                self.delegate?.dataSyncDidStartPhotos?()
            })
            dispatch_async(dispatch_get_main_queue(),{
                self.delegate?.dataSyncDidStartPull?()
            })
            self.pull( usn, endOfLastSync: endOfLastSync, maxCount: 0, continuation: { (success: Bool) -> () in
                if(success) {
                    dispatch_async(dispatch_get_main_queue(),{
                        self.delegate?.dataSyncDidStartPush?()
                    })
                    self.push({
                        self.syncInProgress = false
                        //self.syncRealm!.commitWriteTransaction()
                        dispatch_async(dispatch_get_main_queue(),{
                            self.lastSync = NSDate()
                            self.delegate?.dataSyncDidComplete?(true)
                            self.delegate?.dataSyncDidStartPhotos?()
                            DataSync.manager.pushPhotos()
                        })

                    })
                } else {
                    self.log("Pull failed; eschewing a push")
                    self.syncInProgress = false
                    //self.syncRealm!.cancelWriteTransaction()
                    dispatch_async(dispatch_get_main_queue(),{
                        self.delegate?.dataSyncDidComplete?(false)
                    })
                }
            })
        }
        self.syncCondition.signal()
    }
    
    @objc func syncFire(ti: NSTimer) {
        self.sync()
    }
    
    func defaultRealm() -> RLMRealm {
        return RLMRealm.defaultRealm()
    }
    
    
    func enableSync() -> Bool {
        self.log("Enabling sync")
        self.syncEnabled = true
        return true
    }
    
    func disableSync() -> Bool {
        self.log("Disabling sync")
        self.syncEnabled = false
        return true
    }
    
    func queueThreadTask( task : () -> () ) {
        self.syncQueue.append(task)
        self.syncCondition.signal()
    }
    
    func start() {
        self.log("DataSync Manager Starting");
        let dRealm = self.defaultRealm()
        self.log("Default Realm file is: " + dRealm.path)
        self.log("Checking reachability against " + ServerRoot.address());
        if (self.reachability.isReachable()) {
            self.log("Server " + ServerRoot.address() + " is currently reachable")
            let token = NSUserDefaults.standardUserDefaults().stringForKey("SessionToken")
            if (token != nil) {
                //If connectivity and a token, trigger a sync now.
                self.log("Found a SessionToken: \(token)")
                self.sync()
            }
            self.startPeriodicSyncs()
        } else {
            self.log("Server " + ServerRoot.address() + " is NOT currently reachable")
        }
        // Start up our friendly little worker, "Buttersmack".
        self.syncThread = NSThread(target: self, selector: "syncThreadLoop", object: nil)
        self.syncThread?.start()
        self.log("Sync thread started.")
    }
    
    
    @objc func syncThreadLoop() {
        let currentThread = NSThread.currentThread()
        
        while true {
            
            self.syncCondition.lock()
            while self.syncQueue.count == 0 {
                self.syncCondition.wait()
            }
            
            let block = self.syncQueue.removeAtIndex(0)
            self.syncCondition.unlock()
            //self.log("Found a thread task; running")
            block()
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
    
    @objc func tokenObtained() {
        self.sync()
    }
    
    func log(msg: String) {
        NSLog("DataSync Manager: " + msg)
    }
    
    func downloadPhotos() {
        
    }
    
    func pushPhotos() {
        self.numPhotosUploading = 0
        self.numPhotosCompletedUploading = 0
        self.uploadSession!.getTasksWithCompletionHandler { (_, uploadTasks:[NSURLSessionUploadTask]!, _) in
            for item in uploadTasks {
                if let task = item as? NSURLSessionUploadTask {
                    task.cancel()
                }
            }
        }
        let photos = Photo.objectsWhere("uploaded = false OR uploadedThumbnail = false", [])
        if photos.count > UInt(0) {
            var i = UInt(0)
            while i < photos.count {
                if let photo = photos.objectAtIndex(i) as? Photo {
                    if photo.uploaded != true {
                        if let url = NSURL(string: photo.signedOriginalUploadUrl) {
                            let request = NSMutableURLRequest(URL: url)
                            request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
                            request.HTTPMethod = "PUT"
                            request.setValue("image/jpg", forHTTPHeaderField: "Content-Type")
                            if let data = photo.originalImageData {
                                let uploadTask = self.uploadSession!.uploadTaskWithRequest(request, fromFile: photo.getOriginalFilePath()!)
                                self.numPhotosUploading++
                                uploadTask.resume()
                            } else {
                                print("could not get photo data")
                            }
                        }
                    }
                    if photo.uploadedThumbnail != true {
                        if let url = NSURL(string: photo.signedThumbnailUploadUrl) {
                            let request = NSMutableURLRequest(URL: url)
                            request.cachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
                            request.HTTPMethod = "PUT"
                            request.setValue("image/jpg", forHTTPHeaderField: "Content-Type")
                            if let data = photo.thumbnailImageData {
                                let uploadTask = self.uploadSession!.uploadTaskWithRequest(request, fromFile: photo.getThumbnailFilePath()!)
                                self.numPhotosUploading++
                                uploadTask.resume()
                            } else {
                                print("could not get photo thumbnail data")
                            }
                        }
                    }
                    
                }
                i++
            }
            self.delegate?.dataSyncPhotoUploadStarted?(self.numPhotosUploading)
            print("Uploading \(self.numPhotosUploading) photos")
        } else {
            self.delegate?.dataSyncPhotoUploadStarted?(0)
            self.delegate?.dataSyncPhotoUploadCompleted?(nil)
            print("completed photo uploading")
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let uploadTask = task as? NSURLSessionUploadTask {
            if error != nil {
                print(error)
            } else {
                if var path = uploadTask.response?.URL?.path {
                    path = path.substringWithRange(Range<String.Index>(start: path.startIndex.advancedBy(1), end: path.endIndex)) // get rid of "/"
                    var thumb = false
                    var id = path
                    if path.characters.count > 36 {
                        thumb = true
                        id = path.substringWithRange(Range<String.Index>(start: path.startIndex, end: path.endIndex.advancedBy(-6))) // get rid of "/"
                    }
                    //                    dispatch_async(dispatch_get_main_queue(),{
                    let photos = Photo.objectsWhere("localId = %@", id)
                    if photos.count > UInt(0) {
                        if let photo = photos.objectAtIndex(UInt(0)) as? Photo {
                            photo.beginWriteTransaction()
                            if thumb {
                                photo.uploadedThumbnail = true
                            } else {
                                photo.uploaded = true
                            }
                            photo.commitWriteTransaction()
                            print("photo uploaded")
                            print(photo)
                        }
                    } else {
                        print("couldnt find photo with matching localid")
                    }
                    //                    })
                }
            }
            self.numPhotosCompletedUploading++
            self.delegate?.dataSyncPhotoUploadProgress?(self.numPhotosUploading, numCompleted: self.numPhotosCompletedUploading)
            print("Completed \(self.numPhotosCompletedUploading)/\(self.numPhotosUploading) uploads")
            if self.numPhotosCompletedUploading >= self.numPhotosUploading {
                self.delegate?.dataSyncPhotoUploadCompleted?(nil)
                print("Photo uploads complete")
            }
        }
    }
    
    func pull(currentUsn: Int, endOfLastSync: Int, maxCount: Int, continuation: (Bool) -> () ) {
        self.log("Starting pull")
        let afterUsn = NSURLQueryItem(name: "afterUsn", value: "\(currentUsn)")
        let endOfLastSync = NSURLQueryItem(name: "endOfLastSync", value: "\(endOfLastSync)")

        var components = NSURLComponents(string: Urls.sync)!
        components.queryItems = [ afterUsn, endOfLastSync]

        let userDefaults = NSUserDefaults.standardUserDefaults()
        let mutableURLRequest = NSMutableURLRequest(URL: components.URL!)
        mutableURLRequest.HTTPMethod = "GET"
        mutableURLRequest.setValue("Bearer " + NSUserDefaults.standardUserDefaults().stringForKey("SessionToken")! , forHTTPHeaderField: "Authorization")
        mutableURLRequest.setValue(userDefaults.valueForKey("UserEmail") as? String, forHTTPHeaderField: "eFins-User")
        mutableURLRequest.setValue(UIDevice.currentDevice().name, forHTTPHeaderField: "Device-Name")
        mutableURLRequest.setValue(UIDevice.currentDevice().identifierForVendor!.UUIDString, forHTTPHeaderField: "Device-Id")

        self.log("Getting \(Urls.sync)")
        
        Alamofire.request(mutableURLRequest)
            .response{ (request, response, rawData, error) in
                let data = NSString(data: rawData!, encoding: NSUTF8StringEncoding)
                self.queueThreadTask { () -> () in
                    //println(data)
                    if (error != nil) {
                        self.log("Connection Error, Problem connecting to server: \(error). \(response)")
                    } else if (response?.statusCode == 404) {
                        self.log("404")
                    } else if (response?.statusCode == 401) {
                        self.log("401")
                    } else if (response?.statusCode == 403) {
                        self.log("403")
                    } else if (response?.statusCode == 204) {
                        self.log("Server reports we are up-to-date")
                        continuation(true)
                        return
                    } else if response?.statusCode == 200 {
                        let json = JSON(data: data!.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
                        let newUsn = json["highestUsn"].int
                        self.log("Got reply to sync request; updating local DB from \(currentUsn) to \(newUsn!)")
                        if(self.digestResults(json) == true) {
                            let defaults = NSUserDefaults.standardUserDefaults()
                            defaults.setInteger(newUsn!, forKey: "currentUsn")
                            defaults.setInteger(json["timestamp"].int!, forKey: "endOfLastSync")
                            self.log("After a successful pull, setting currentUsn to \(newUsn!)")
                            continuation(true)
                            return
                        } else {
                            self.log("Failed to digest server results; discarding pulled data")
                        }
                    } else {
                        self.log(data?.stringByStandardizingPath ?? "")
                    }
                    continuation(false)
                }
        }

        
        
    }
    
    func push(continuation: () -> ()) {
        let dRealm = self.syncRealm!
        let dict = [String: AnyObject]()
        var json = JSON(dict)
        var nObjsToPush = 0
        
        self.log("Starting push")
        
        json["models"] = JSON([String: AnyObject]())
        for (key, model) in Models {
            //self.log("\(key)")
            var tempArray: [JSON] = []
            let results = model.objectsInRealm(dRealm, "dirty == true")
            for object in results {
                let eObject = object as! EfinsModel
                tempArray.append(eObject.toJSON())
            }
            //println("tmp array size \(count(tempArray))")
            if tempArray.count > 0 {
                json["models"][key] = JSON(tempArray)
                nObjsToPush += tempArray.count
            }
        }
        
        if nObjsToPush == 0 {
            self.log("Nothing to push.")
            return continuation()
        }
        
        self.log(json.rawString()!)
        var components = NSURLComponents(string: Urls.sync)!
        let mutableURLRequest = NSMutableURLRequest(URL: components.URL!)
        mutableURLRequest.HTTPMethod = "POST"
        try! mutableURLRequest.HTTPBody = json.rawData()
        mutableURLRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.setValue("Bearer " + NSUserDefaults.standardUserDefaults().stringForKey("SessionToken")! , forHTTPHeaderField: "Authorization")
        mutableURLRequest.setValue(NSUserDefaults.standardUserDefaults().valueForKey("UserEmail") as? String, forHTTPHeaderField: "eFins-User")
        mutableURLRequest.setValue(UIDevice.currentDevice().name, forHTTPHeaderField: "Device-Name")
        mutableURLRequest.setValue(UIDevice.currentDevice().identifierForVendor!.UUIDString, forHTTPHeaderField: "Device-Id")

        self.log("Posting to \(Urls.sync)")
        Alamofire.request(mutableURLRequest)
            .response{ (request, response, rawData, error) in
                let data = NSString(data: rawData!, encoding: NSUTF8StringEncoding)
                self.queueThreadTask { () -> () in
                    if (error != nil) {
                        self.log("Connection Error, Problem connecting to server: \(error). \(response)")
                    } else if (response?.statusCode == 404) {
                        self.log("404")
                    } else if (response?.statusCode == 401) {
                        self.log("401")
                    } else if (response?.statusCode == 403) {
                        self.log("403")
                    } else if (response?.statusCode == 204) {
                        self.log("Server reports 204, WTF?")
                    } else if response?.statusCode == 200 {
                        self.log("Successful push to server")
                        self.deleteOrUpdateLocalObjects(data! as String)
                        continuation()
                        return
                    } else {
                        self.log("Failed to post locally created data to server; will try again later")
                    }
            
                    continuation()
                }
        }
    }
    
    func digestResults(json: JSON) -> Bool {
        var newEntities: [RLMObject] = []
        let start = NSDate()
        self.syncRealm!.beginWriteTransaction()
        for (key, subJson): (String, JSON) in json {
            if(key == "models") {
                self.log("Setting data for all models")
                
                for (nkey, modelArrayJson): (String, JSON) in subJson {
                    //self.log("Handling \(nkey)")
                    // This whole switch statement is only needed because we don't have a good way of turning a string into a Swift class yet
                    switch(nkey) {
                        case "Action":
                            Action.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "Activity":
                            Activity.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "Agency":
                            Agency.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "AgencyFreetextCrew":
                            AgencyFreetextCrew.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "AgencyVessel":
                            AgencyVessel.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "Catch":
                            Catch.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "ContactType":
                            ContactType.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "EnforcementActionTaken":
                            EnforcementActionTaken.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "EnforcementActionType":
                            EnforcementActionType.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "Fishery":
                            Fishery.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "FreeTextCrew":
                            FreeTextCrew.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "PatrolLog":
                            PatrolLog.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "Person":
                            Person.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "Photo":
                            Photo.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "Port":
                            Port.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "Species":
                            Species.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "User":
                            User.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "Vessel":
                            Vessel.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "VesselType":
                            VesselType.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        case "ViolationType":
                            ViolationType.ingest(modelArrayJson, syncRealm: self.syncRealm!)
                        default:
                            self.log("Unknown/unimplemented model key \(key) in server json")
                    }
                }
            }
        }
        self.syncRealm!.commitWriteTransaction()
        let end = NSDate()
        let timeInterval: Double = end.timeIntervalSinceDate(start)
        self.log("Populated DB with new models and data: \(timeInterval) s")
        self.setRelationships(json["relations"])
        return true
    }
    
    func setRelationships(rJson: JSON) -> Bool {
        self.log("Setting relationships/associations on new models")
        let start = NSDate()
        self.syncRealm!.beginWriteTransaction()
        for (index, aJson): (String, JSON) in rJson {
            if aJson["type"] == "BelongsTo" {
                handleBelongsTo(aJson)
            } else {
                handleBelongsToMany(aJson)
            }
        }
        self.syncRealm!.commitWriteTransaction()
        let end = NSDate()
        let timeInterval: Double = end.timeIntervalSinceDate(start)
        self.log("All relationships set: \(timeInterval) s")
        return true
    }
    
    
    func handleBelongsToMany(aJson: JSON) -> Bool {
        let dRealm = self.syncRealm!
        
       
        let source = aJson["sourceModel"].stringValue
        let target = aJson["targetModel"].stringValue
        let thisAs = aJson["as"].stringValue
        self.log("\(thisAs) is a many-to-many between \(source) and \(target) ")
        var sourceModel = Models[source]!
        var targetModel = Models[target]!
        var sourceSchema = dRealm.schema.schemaForClassName(source)
        var targetSchema = dRealm.schema.schemaForClassName(target)
        if (sourceSchema == nil) {
            self.log("Problem: no Realm schema found for JSON object named \(source)")
        }
        if (targetSchema == nil) {
            self.log("Problem: no Realm schema found for JSON object named \(target)")
        }
        
        var found = 0
        var foundOnTarget = false
        for p in sourceSchema!.properties {
            let property: RLMProperty = p as! RLMProperty
            
            if property.type == RLMPropertyType.Array && property.objectClassName == target && property.name == thisAs {
                //self.log("Found an array property named \(property.name) on \(source); this matches JSON property \(thisAs)")
                found++
            }
        }
        for p in targetSchema!.properties {
            let property: RLMProperty = p as! RLMProperty
            
            if property.type == RLMPropertyType.Array && property.objectClassName == source {
                //self.log("Found an array property named \(property.name) on \(target); deferring and will populate in other direction")
                foundOnTarget = true
            }
        }
        if foundOnTarget {return true}
        if(found == 0) {
            self.log("The JSON expected a relationship named \(thisAs) on \(source) but we didn't find one in the local (Realm) schema")
            self.log("CORRECT YOUR SCHEMA!!!!!")
        } else if(found > 1) {
            self.log("Oops, we have multiple choices for an association for \(thisAs) on \(source)")
            self.log("CORRECT YOUR SCHEMA!!!!!")
        } else {
            // Now, we gotta fetch all the models referred to by the association and set their targets.  This has got to be massively inefficient.
            for (_,  idHash) in aJson["idmap"] {
                let idDict = idHash.dictionaryObject!
                let sid : String = "\(source)Id"
                let tid : String = "\(target)Id"
                let sourceId = idDict[sid]!.stringValue
                let targetId = idDict[tid]!.stringValue
                self.log("Setting source \(source)Id \(sourceId) to refer to target \(target)Id \(targetId)")
                let s = sourceModel.objectsInRealm(dRealm, "id == %@", sourceId).firstObject() as! EfinsModel
                let t = targetModel.objectsInRealm(dRealm, "id == %@", targetId).firstObject() as! EfinsModel
                let currentAssocs : RLMArray = s.valueForKey(thisAs) as! RLMArray
                let i = currentAssocs.indexOfObject(t)
                if i == UInt(NSNotFound) {
                    currentAssocs.addObject(t)
                }
            }
        }
        return(true)
    }
    
    
    func handleBelongsTo(aJson: JSON) -> Bool {
        let dRealm = self.syncRealm!
        let source = aJson["sourceModel"].stringValue
        let target = aJson["targetModel"].stringValue
        let foreignKey = aJson["foreignKey"].stringValue
        let assocName = aJson["clientAssociationName"].stringValue
        //self.log("\(assocName) on \(source) is a one-to-one or one-to-many with \(target) ")
        var sourceModel = Models[source]!
        var targetModel = Models[target]!
        var sourceSchema = dRealm.schema.schemaForClassName(source)
        var targetSchema = dRealm.schema.schemaForClassName(target)
        if (sourceSchema == nil) {
            self.log("Problem: no Realm schema found for JSON object named \(source)")
        }
        if (targetSchema == nil) {
            self.log("Problem: no Realm schema found for JSON object named \(target)")
        }
        var found = 0
        var foundType = RLMPropertyType.Object
        for p in sourceSchema!.properties {
            let property: RLMProperty = p as! RLMProperty
            if property.type == RLMPropertyType.Object && property.objectClassName == target && property.name == assocName {
                //self.log("Found a property named \(property.name) on \(source); this matches JSON property \(assocName)")
                found++
            } else if property.type == RLMPropertyType.Array && property.objectClassName == target && property.name == assocName {
                //self.log("Found an array property named \(property.name) on \(source); this matches JSON property \(assocName)")
                foundType = RLMPropertyType.Array
                found++
            }
        }
        if(found == 0) {
            self.log("The JSON expected a relationship  named \(assocName) on \(source) but we didn't find one in the local (Realm) schema")
            self.log("CORRECT YOUR SCHEMA!!!!!")
        } else if(found > 1) {
            self.log("Oops, we have multiple choices for an association for  \(assocName) on \(source)")
            self.log("CORRECT YOUR SCHEMA!!!!!")
        } else {
            // Now, we gotta fetch all the models referred to by the association and set their targets.  This has got to be massively inefficient.
            for (_, idHash) in aJson["idmap"] {
                let idDict = idHash.dictionaryObject!
                let sid : String = "id"
                let tid : String = foreignKey
                let sourceId = idDict[sid]!.stringValue
                let targetId = idDict[tid]!.stringValue
                if targetId == nil {continue}
                
                
                if foundType == RLMPropertyType.Object {
                    self.log("Setting foreign key to refer to target as \(targetId)")
                    let s = sourceModel.objectsInRealm(dRealm, "id == %@", sourceId).firstObject() as! EfinsModel
                    let t = targetModel.objectsInRealm(dRealm, "id == %@", targetId).firstObject() as! EfinsModel
                    s.setValue(t, forKey: assocName)
                } else {
                    let s = sourceModel.objectsInRealm(dRealm, "id == %@", sourceId).firstObject() as! EfinsModel
                    let t = targetModel.objectsInRealm(dRealm, "id == %@", targetId).firstObject() as! EfinsModel
                    let currentAssocs : RLMArray = s.valueForKey(assocName) as! RLMArray
                    let i = currentAssocs.indexOfObject(t)
                    if i == UInt(NSNotFound) {
                        currentAssocs.addObject(t)
                    }

                    
                }
            }
        }
        return true;
    }
    
    func deleteOrUpdateLocalObjects(jsonString: String) -> Bool {
        let json = JSON(data: jsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
        let dRealm = self.syncRealm!
        let defaults = NSUserDefaults.standardUserDefaults()
        let start = NSDate()
        dRealm.beginWriteTransaction()
        for (key, subJson): (String, JSON) in json {
            for (nkey, newInfo): (String, JSON) in subJson {
                let newId = newInfo.stringValue
                self.log("Handling \(nkey) remapping to \(newId)")
                let joker = Models[key]
                let queryResults = joker?.objectsInRealm(dRealm, "id == '\(nkey)'")
                if queryResults?.count <= 0 {
                    self.log("No \(key) object was found for local id \(nkey)")
                } else {
                    let modelObject = queryResults?.firstObject() as! EfinsModel
                    let newModelObject = joker?.init(object: modelObject) as! EfinsModel
                    newModelObject.id = newId
                    //Don't actually set the USN here.  By definition, this model has a USN of -1, and the USN will get set to the correct number on the next pull.
                    //Since it's no longer dirty it won't ever get pushed again.
                    newModelObject.dirty = false
                    self.log("Deleting \(key) \(nkey) to \(newId)")
                    dRealm.deleteObject(modelObject)
                    dRealm.addObject(newModelObject)
                }
            }
        }
        dRealm.commitWriteTransaction()
        
        
        let fin = NSDate()
        let timeInterval: Double = fin.timeIntervalSinceDate(start)
        self.log("Remove local copies of pushed data: \(timeInterval) s")

        return true
    }
    
}
