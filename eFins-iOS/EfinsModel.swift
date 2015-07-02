//
//  efinsModel.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/25/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm
import SwiftyJSON

class EfinsModel : RLMObject {
    dynamic var id = NSUUID.init().UUIDString
    dynamic var localId = NSUUID.init().UUIDString
    dynamic var usn : Int = -1
    dynamic var createdAt : NSDate = NSDate(timeIntervalSinceNow: 0)
    dynamic var updatedAt : NSDate = NSDate(timeIntervalSinceNow: 0)  // there are no hooks in Realm yet, so we can't really update this automatically as the object is updated
    dynamic var dirty = true
    
    override class func primaryKey() -> String {
        return "id"
    }
    
    class func ingest(json: JSON, syncRealm: RLMRealm) -> [RLMObject] {
        var newEntities : [RLMObject] = []
        let classType = self.self
        let defaults = NSUserDefaults.standardUserDefaults()
        let currentUsn = defaults.integerForKey("currentUsn")
        println("currentUsn \(currentUsn)")
        for (index: String, model: JSON) in json {
            var dictionary = model.dictionaryObject
            let idAsString = model["id"].stringValue
            dictionary?.updateValue(idAsString, forKey: "id")
        
            // Convert all date strings to NSDates
            let dateFormatter : NSDateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            for (k,v) in dictionary! {
                if let dateString = v as? String {
                    let newV = dateFormatter.dateFromString(dateString)
                    if(newV != nil) {
                        dictionary?.updateValue(newV!, forKey: k)
                    }
                }
            }
            
            for (key, var value) in dictionary! {
                let handler = self.getSpecialDataPropertyHandler(key)
                if handler != nil {
                    if value as! NSObject == NSNull() {
                        value = "nothing"
                    }
                    dictionary?.updateValue(handler!(value as! String), forKey: key)
                }
            }
            if model["usn"].intValue > currentUsn {
                let val = model["usn"].intValue
                println("including \(val)")
                newEntities.append( classType.createOrUpdateInRealm(syncRealm, withObject:dictionary!))
            }
        }
        println("New Entity Count \(newEntities.count)")
        for ne in newEntities as! [EfinsModel] {
            ne.dirty = false
        }
        return newEntities
    }
    
    func toJSON() -> JSON {
        var json = JSON([String: AnyObject]())
        let dRealm = RLMRealm.defaultRealm()
        let className = self.description.componentsSeparatedByString(" ")[0]
        let sourceSchema = dRealm.schema.schemaForClassName(className)
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.LongStyle
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        let excludedArray = self.doNotPush()

        for p in sourceSchema.properties {
            let property: RLMProperty = p as! RLMProperty
            if contains(excludedArray, property.name) {
                continue
            }
            
            if property.type == RLMPropertyType.Array {
                var idArray = [String]()
                let rawArray = self[property.name] as? RLMArray
                if (rawArray != nil) && (rawArray?.count > 0) {
                    for val in rawArray! {
                        let m = val as! EfinsModel
                        idArray.append(m.id)
                        json[property.name] = JSON(idArray)
                    }
                }
            } else if property.type == RLMPropertyType.Object {
                let obj = self[property.name] as? RLMObject
                if obj != nil {
                    json[property.name] = JSON(self[property.name].id)
                }
            } else if property.type == RLMPropertyType.Date {
                let obj = self[property.name] as? NSDate
                if obj != nil {
                    //json[property.name] = JSON(obj!.timeIntervalSince1970)
                    json[property.name] = JSON(dateFormatter.stringFromDate(obj!))

                }
            } else if property.type == RLMPropertyType.Data {
                let obj = self[property.name] as? NSData
                if obj != nil {
                    json[property.name] = JSON(obj!.base64EncodedStringWithOptions(nil))
                }

            } else {
                if !(contains(["dirty", "localId"], property.name)) {
                    json[property.name] = JSON(self.valueForKey(property.name)!)
                }
            }
        }
        return json
        
    }
    
    func beginWriteTransaction() {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
    }
    
    func commitWriteTransaction() {
        self.dirty = true
        let realm = RLMRealm.defaultRealm()
        realm.commitWriteTransaction()
    }
    
    func doNotPush() -> [String] {
        return []
    }
    
    class func getSpecialDataPropertyHandler(property: String) -> ((String) -> NSData)? {
        return nil
    }
    
    
}
