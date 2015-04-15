//
//  Constants.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

#if DEBUG_SERVER
//let SERVER_ROOT = "http://localhost:3002/"
let SERVER_ROOT = "http://10.0.1.7:3002/"
#else
let SERVER_ROOT = "https://efins.org/"
#endif

struct Urls {
    static let root = SERVER_ROOT

    // requires email, password
    static let register = "\(root)auth/register"
    static let getToken = "\(root)auth/getToken"

    // requires bearer token
    static let expireToken = "\(root)auth/expireToken"
    static let passwordReset = "\(root)auth/requestPasswordReset"
}

let ADMIN_EMAIL = "support@efins.org"

let locale = NSLocale.currentLocale()

func getDateFormatter() -> NSDateFormatter {
    let formatter = NSDateFormatter()
    formatter.dateFormat = NSDateFormatter.dateFormatFromTemplate("yyyy-MM-dd 'at' HH:mm", options: 0, locale: locale)
    formatter.locale = locale
    return formatter
}

var Models: [String: RLMObject.Type] = [
    "Agency": Agency.self,
    "User": User.self,
    "AgencyVessel": AgencyVessel.self,
    "PatrolLog": PatrolLog.self,
    "FreeTextCrew": FreeTextCrew.self,
    "Species": Species.self,
    "Port": Port.self,
    "Activity": Activity.self,
    "Catch": Catch.self,
    "RegulatoryCode": RegulatoryCode.self,
    "ContactType": ContactType.self,
    "VesselType": VesselType.self,
    "Vessel": Vessel.self,
    "Fishery": Fishery.self,
    "Person": Person.self,
    "Action": Action.self,
    "Photo": Photo.self,
    "ViolationType": ViolationType.self,
    "EnforcementActionType": EnforcementActionType.self,
    "EnforcementActionTaken": EnforcementActionTaken.self
]

func getRealmModelProperty(model:String, propertyName:String) -> RLMProperty? {
    let realm = RLMRealm.defaultRealm()
    let properties = realm.schema.schemaForClassName(model).properties as! [RLMProperty]
    for prop in properties {
        if prop.getterName == propertyName {
            return prop
        }
    }
    return nil
}

class _RecentValues {
    
    func increment(item: RLMObject, model: RLMObject, property: RLMProperty) {
        let key = self.getKey(item, model: model, property: property)
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(defaults.integerForKey(key) + 1, forKey: key)
        debugValues()
    }
    
    func getKey(item: RLMObject, model: RLMObject, property: RLMProperty) -> String {
        let id = item.valueForKey("localid") as! String
        return "recent-values,\(model.objectSchema.className),\(property.name),\(id)"
    }
    
    func debugValues() {
        println("===== Stored Recently Used Values =====")
        for (key, value) in NSUserDefaults.standardUserDefaults().dictionaryRepresentation() {
            if (key as! NSString).containsString("recent-values") {
                println("\(key): \(value)")
            }
        }
        println("======================================= ")
    }
    
    func getRecent(model: RLMObject, property: RLMProperty) -> [RLMObject] {
        var recent = [RLMObject]()
        var items = [String:Int]()
        var sortedKeys = [String]()
        for (key, value) in NSUserDefaults.standardUserDefaults().dictionaryRepresentation() {
            if sortedKeys.count > 9 {
                break
            }
            if (key as! NSString).containsString("recent-values") && (key as! NSString).containsString(model.objectSchema.className) && (key as! NSString).containsString(property.name) {
                var parts = split(key as! String) { $0 == ","}
                let id = parts[3]
                items[id] = value.integerValue
                sortedKeys.append(id)
            }
        }
        sortedKeys.sort {
            items[$0] > items[$1]
        }
        println(sortedKeys)
        let Model = Models[property.objectClassName]
        for id in sortedKeys {
            NSLog("localid = %@", id)
            println(Model)
            let results = Model!.objectsWithPredicate(NSPredicate(format: "localid = %@", id))
            println(results)
            if results.count > 0 {
                recent.append(results.objectAtIndex(0) as! RLMObject)
            }
        }
        return recent
    }
}

let RecentValues = _RecentValues()



