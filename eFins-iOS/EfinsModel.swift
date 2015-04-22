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
    dynamic var id =  NSUUID.init().UUIDString
    dynamic var usn : Int = -1
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    
    override class func primaryKey() -> String {
        return "id"
    }
    
    class func ingest(json: JSON) -> [RLMObject] {
        var newEntities : [RLMObject] = []
        let classType = self.self
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
            newEntities.append( classType.createOrUpdateInDefaultRealmWithObject(dictionary!) )
        }
        return newEntities
    }
    
    class func setRelationships(json : JSON) -> Bool {
        return true
    }
}
