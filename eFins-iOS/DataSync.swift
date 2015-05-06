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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "tokenObtained", name: TokenObtainedNotification, object: nil)

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
        let token = NSUserDefaults.standardUserDefaults().stringForKey("SessionToken")
        if (token == nil) {
            self.log("Synchronization not yet possible; no session token; yielding.");
            return
        }
        let prio = DISPATCH_QUEUE_PRIORITY_DEFAULT
        let queue = dispatch_get_global_queue(prio, 0)
        self.syncInProgress = true
        dispatch_async(queue) {
            //self.log("Sync executing on background queue")
            let defaults = NSUserDefaults.standardUserDefaults()
            let usn = defaults.integerForKey("currentUsn")
            let endOfLastSync = defaults.integerForKey("endOfLastSync")
            
            //self.pull( usn, endOfLastSync: endOfLastSync, maxCount: 0)
            self.pull( 0, endOfLastSync: endOfLastSync, maxCount: 0, continuation: { (success: Bool) -> () in
                self.log("Entered continuation")
                if(success) {
                    self.log("starting push")
                    self.push({
                        self.syncInProgress = false
                    })
                } else {
                    self.log("Pull failed; eschewing a push")
                    self.syncInProgress = false
                }
            })

            
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
    
    @objc func tokenObtained() {
        self.sync()
    }
    
    func log(msg: String) {
        NSLog("DataSync Manager: " + msg)
    }
    
    func pull(currentUsn: Int, endOfLastSync: Int, maxCount: Int, continuation: (Bool) -> () ) {
        let afterUsn = NSURLQueryItem(name: "afterUsn", value: "\(currentUsn)")
        let endOfLastSync = NSURLQueryItem(name: "endOfLastSync", value: "\(endOfLastSync)")

        var components = NSURLComponents(string: Urls.sync)!
        components.queryItems = [ afterUsn, endOfLastSync]

        let mutableURLRequest = NSMutableURLRequest(URL: components.URL!)
        mutableURLRequest.HTTPMethod = "GET"
        mutableURLRequest.setValue("Bearer " + NSUserDefaults.standardUserDefaults().stringForKey("SessionToken")! , forHTTPHeaderField: "Authorization")
        self.log("Getting \(Urls.sync)")
        
        Alamofire.request(mutableURLRequest)
            .responseString { (request, response, data, error) in
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
    
    func push(continuation: () -> ()) {
        let dRealm = self.defaultRealm()
        let dict = [String: AnyObject]()
        var json = JSON(dict)
        json["models"] = JSON([String: AnyObject]())
        for (key, model) in Models {
            //self.log("\(key)")
            var tempArray: [JSON] = []
            let results = model.objectsInRealm(dRealm, "dirty == true")
            for object in results {
                let eObject = object as! EfinsModel
                tempArray.append(eObject.toJSON())
            }
            if count(tempArray) > 0 {
                json["models"][key] = JSON(tempArray)
            }
        }
        self.log(json.rawString()!)
        var components = NSURLComponents(string: Urls.sync)!
        let mutableURLRequest = NSMutableURLRequest(URL: components.URL!)
        mutableURLRequest.HTTPMethod = "POST"
        mutableURLRequest.HTTPBody = json.rawData()
        mutableURLRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        mutableURLRequest.setValue("Bearer " + NSUserDefaults.standardUserDefaults().stringForKey("SessionToken")! , forHTTPHeaderField: "Authorization")
        self.log("Posting to \(Urls.sync)")
        Alamofire.request(mutableURLRequest)
            .responseString { (request, response, data, error) in
                println(data)
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
                    continuation()
                    return
                } else {
                    self.log("Failed to post locally created data to server; will try again later")
                }
        
                continuation()
        }
    }
    
    func digestResults(json: JSON) -> Bool {
        let dRealm = self.defaultRealm()
        dRealm.beginWriteTransaction()
        var newEntities: [RLMObject] = []
        
        let start = NSDate()
        for (key: String, subJson: JSON) in json {
            if(key == "models") {
                self.log("Setting data for all models")
                
                for (nkey: String, modelArrayJson: JSON) in subJson {
                    //self.log("Handling \(nkey)")
                    // This whole switch statement is only needed because we don't have a good way of turning a string into a Swift class yet
                    switch(nkey) {
                        case "Action":
                            Action.ingest(modelArrayJson)
                        case "Activity":
                            Activity.ingest(modelArrayJson)
                        case "Agency":
                            Agency.ingest(modelArrayJson)
                        case "AgencyVessel":
                            AgencyVessel.ingest(modelArrayJson)
                        case "Catch":
                            Catch.ingest(modelArrayJson)
                        case "ContactType":
                            ContactType.ingest(modelArrayJson)
                        case "EnforcementActionTaken":
                            EnforcementActionTaken.ingest(modelArrayJson)
                        case "EnforcementActionType":
                            EnforcementActionType.ingest(modelArrayJson)
                        case "Fishery":
                            Fishery.ingest(modelArrayJson)
                        case "FreeTextCrew":
                            FreeTextCrew.ingest(modelArrayJson)
                        case "PatrolLog":
                            PatrolLog.ingest(modelArrayJson)
                        case "Person":
                            Person.ingest(modelArrayJson)
                        case "Photo":
                            Photo.ingest(modelArrayJson)
                        case "Port":
                            Port.ingest(modelArrayJson)
                        case "Species":
                            Species.ingest(modelArrayJson)
                        case "User":
                            User.ingest(modelArrayJson)
                        case "Vessel":
                            Vessel.ingest(modelArrayJson)
                        case "VesselType":
                            VesselType.ingest(modelArrayJson)
                        case "ViolationType":
                            ViolationType.ingest(modelArrayJson)
                        default:
                            self.log("Unknown/unimplemented model key \(key) in server json")
                    }
                }
            }
        }
        let end = NSDate()
        let timeInterval: Double = end.timeIntervalSinceDate(start)
        self.log("Populated DB with new models and data: \(timeInterval) s")
        
        self.setRelationships(json["relations"])


        dRealm.commitWriteTransaction()

        return true
    }
    
    func setRelationships(rJson: JSON) -> Bool {
        self.log("Setting relationships/associations on new models")
        let start = NSDate()
        for (index: String, aJson : JSON) in rJson {
            if aJson["type"] == "BelongsTo" {
                handleBelongsTo(aJson)
            } else {
                handleBelongsToMany(aJson)
            }
        }
        let end = NSDate()
        let timeInterval: Double = end.timeIntervalSinceDate(start)
        self.log("All relationships set: \(timeInterval) s")
        return true
    }
    
    
    func handleBelongsToMany(aJson: JSON) -> Bool {
        let dRealm = self.defaultRealm()
        
       
        let source = aJson["sourceModel"].stringValue
        let target = aJson["targetModel"].stringValue
        let thisAs = aJson["as"].stringValue
        //self.log("\(thisAs) is a many-to-many between \(source) and \(target) ")
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
        for p in sourceSchema.properties {
            let property: RLMProperty = p as! RLMProperty
            
            if property.type == RLMPropertyType.Array && property.objectClassName == target && property.name == thisAs {
                //self.log("Found an array property named \(property.name) on \(source); this matches JSON property \(thisAs)")
                found++
            }
        }
        for p in targetSchema.properties {
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
            for (index, idHash : JSON) in aJson["idmap"] {
                let idDict = idHash.dictionaryObject!
                let sid : String = "\(source)Id"
                let tid : String = "\(target)Id"
                let sourceId = idDict[sid]!.stringValue
                let targetId = idDict[tid]!.stringValue
                //self.log("Setting source \(source)Id \(sourceId) to refer to target \(target)Id \(targetId)")
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
        let dRealm = self.defaultRealm()
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
        for p in sourceSchema.properties {
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
            for (index, idHash : JSON) in aJson["idmap"] {
                let idDict = idHash.dictionaryObject!
                let sid : String = "id"
                let tid : String = foreignKey
                let sourceId = idDict[sid]!.stringValue
                let targetId = idDict[tid]!.stringValue
                if targetId == nil {continue}
                
                
                if foundType == RLMPropertyType.Object {
                    //self.log("Setting foreign key to refer to target as \(targetId)")
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
    
}
