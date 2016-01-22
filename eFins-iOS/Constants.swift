//
//  Constants.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class ServerRoot
{
    private class var isRunningSimulator: Bool
        {
        get
        {
            return TARGET_OS_SIMULATOR != 0 // Use this line in Xcode 7 or newer
        }
    }
    
    class func address() -> String {
        if ServerRoot.isRunningSimulator {
            return "http://localhost:3002/"
        } else {
            return "http://efins.org/"
        }
    }
}



let CHART_MBTILES = "http://d22rw30n9mffwa.cloudfront.net/charts.mbtiles"
let BASEMAP_MBTILES = "http://d22rw30n9mffwa.cloudfront.net/efins-basemap.mbtiles"
let SENTRY_DSN = "https://2c4ae4ac92c84b0ea1cedc913ee39408:c5cdf2a5caec4910bd5aef75e4d70de8@app.getsentry.com/44757"
let PHOTOS_BUCKET = "efins-photos"

func chartPath() -> String? {
    let fileManager = NSFileManager.defaultManager()
    if let cachePath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] as? String {
        return cachePath.stringByAppendingString("charts.mbtiles")
    } else {
        return nil
    }
}

func basemapPath() -> String? {
    let fileManager = NSFileManager.defaultManager()
    if let cachePath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] as? String {
        return cachePath.stringByAppendingString("efins-basemap.mbtiles")
    } else {
        return nil
    }
}

func tilesExist() -> Bool {
    let filemgr = NSFileManager.defaultManager()
    if filemgr.fileExistsAtPath(chartPath()!) {
        if filemgr.fileExistsAtPath(basemapPath()!) {
            return true
        } else {
            return false
        }
    } else {
        return false
    }
}

struct Urls {
    static let root = ServerRoot.address()

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

func getShorthandDayFormatter() -> NSDateFormatter {
    let formatter = NSDateFormatter()
    formatter.dateFormat = NSDateFormatter.dateFormatFromTemplate("MM-dd", options: 0, locale: locale)
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
    let properties = realm.schema.schemaForClassName(model)!.properties as! [RLMProperty]
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
        print("===== Stored Recently Used Values =====")
        for (key, value) in NSUserDefaults.standardUserDefaults().dictionaryRepresentation() {
            if (key as NSString).containsString("recent-values") {
                print("\(key): \(value)")
            }
        }
        print("======================================= ")
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
                var parts = key.componentsSeparatedByString(",")
                let id = parts[3]
                items[id] = value.integerValue
                sortedKeys.append(id)
            }
        }
        sortedKeys.sortInPlace {
            items[$0] > items[$1]
        }
        let Model = Models[propertyClassName]
        var Model2:RLMObject.Type?
        if secondaryProperty != nil {
            Model2 = Models[secondaryProperty!.objectClassName!]
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
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler:{ (ACTION :UIAlertAction)in
        print("ok")
    }))
    view.presentViewController(alert, animated: true, completion: nil)
}

func confirm(title:String, message:String, view:UIViewController, next:() -> ()) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler:{ (ACTION :UIAlertAction)in
        print("cancelled")
    }))
    alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler:{ (ACTION :UIAlertAction)in
        next()
    }))
    view.presentViewController(alert, animated: true, completion: nil)
}


