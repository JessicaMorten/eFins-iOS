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
let SERVER_ROOT = "http://10.0.1.10:3002/"
//let SERVER_ROOT = "http://efins.org/"
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
    static let sync = "\(root)api/1/sync"
}

let ADMIN_EMAIL = "support@efins.org"

let locale = NSLocale.currentLocale()

func getDateFormatter() -> NSDateFormatter {
    let formatter = NSDateFormatter()
    formatter.dateFormat = NSDateFormatter.dateFormatFromTemplate("yyyy-MM-dd 'at' HH:mm", options: 0, locale: locale)
    formatter.locale = locale
    return formatter
}

func getDayDateFormatter() -> NSDateFormatter {
    let formatter = NSDateFormatter()
    formatter.dateFormat = NSDateFormatter.dateFormatFromTemplate("yyyy-MM-dd", options: 0, locale: locale)
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
    "ContactType": ContactType.self,
    "VesselType": VesselType.self,
    "Vessel": Vessel.self,
    "Fishery": Fishery.self,
    "Person": Person.self,
    "Action": Action.self,
    "Photo": Photo.self,
    "ViolationType": ViolationType.self,
    "EnforcementActionType": EnforcementActionType.self,
    "EnforcementActionTaken": EnforcementActionTaken.self,
    "AgencyFreetextCrew": AgencyFreetextCrew.self
]

func getRealmModelProperty(model:String, propertyName:String) -> RLMProperty {
    let realm = RLMRealm.defaultRealm()
    let properties = realm.schema.schemaForClassName(model).properties as! [RLMProperty]
    for prop in properties {
        if prop.name == propertyName {
            return prop
        }
    }
    NSException(name: "NoProperty", reason: "Property \(model).\(propertyName) could not be identified", userInfo: nil).raise()
    return RLMProperty()
}

class _RecentValues {
    
    func increment(item: RLMObject, model: RLMObject, propertyClassName: String, propertyName: String) {
        let key = self.getKey(item, model: model, propertyClassName: propertyClassName, propertyName: propertyName)
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setInteger(defaults.integerForKey(key) + 1, forKey: key)
        debugValues()
    }
    
    func getKey(item: RLMObject, model: RLMObject, propertyClassName: String, propertyName: String) -> String {
        let id = item.valueForKey("localid") as! String
        return "recent-values,\(propertyClassName),\(propertyName),\(id)"
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
    
    func getRecent(model: RLMObject, propertyClassName: String, propertyName: String, secondaryProperty: RLMProperty?) -> [RLMObject] {
        var recent = [RLMObject]()
        var items = [String:Int]()
        var sortedKeys = [String]()
        for (key, value) in NSUserDefaults.standardUserDefaults().dictionaryRepresentation() {
            if sortedKeys.count > 9 {
                break
            }
            if (key as! NSString).containsString("recent-values") && (key as! NSString).containsString(model.objectSchema.className) && ((key as! NSString).containsString(propertyName) || (secondaryProperty != nil && (key as! NSString).containsString(secondaryProperty!.name))) {
                var parts = split(key as! String) { $0 == ","}
                let id = parts[3]
                items[id] = value.integerValue
                sortedKeys.append(id)
            }
        }
        sortedKeys.sort {
            items[$0] > items[$1]
        }
        let Model = Models[propertyClassName]
        var Model2:RLMObject.Type?
        if secondaryProperty != nil {
            Model2 = Models[secondaryProperty!.objectClassName]
        }
        for id in sortedKeys {
            let results = Model!.objectsWithPredicate(NSPredicate(format: "localid = %@", id))
            if results.count > 0 {
                recent.append(results.objectAtIndex(0) as! RLMObject)
            } else {
                if Model2 != nil {
                    let results2 = Model2!.objectsWithPredicate(NSPredicate(format: "localid = %@", id))
                    if results2.count > 0 {
                        recent.append(results2.objectAtIndex(0) as! RLMObject)
                    }
                }
            }
        }
        return recent
    }
}

let RecentValues = _RecentValues()

func rlmArrayToNSArray(rlmArray:RLMArray) -> [RLMObject] {
    var items = [RLMObject]()
    var i = 0
    while i < Int(rlmArray.count) {
        items.append(rlmArray.objectAtIndex(UInt(i)) as! RLMObject)
        i++
    }
    return items
}

import UIKit

func alert(title:String, message:String, view:UIViewController) {
    var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler:{ (ACTION :UIAlertAction!)in
        println("ok")
    }))
    view.presentViewController(alert, animated: true, completion: nil)
}

func confirm(title:String, message:String, view:UIViewController, next:() -> ()) {
    var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler:{ (ACTION :UIAlertAction!)in
        println("cancelled")
    }))
    alert.addAction(UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default, handler:{ (ACTION :UIAlertAction!)in
        next()
    }))
    view.presentViewController(alert, animated: true, completion: nil)
}


