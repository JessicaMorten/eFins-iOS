//
//  User.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm
import SwiftyJSON

class User: EfinsModel {
    dynamic var email = ""
    dynamic var name = ""
    dynamic var agency: Agency?
    
    
    //Belongs-to relationships
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "user") as! [Activity]
    }
    
    var patrolLogs: [PatrolLog] {
        return linkingObjectsOfClass("PatrolLog", forProperty: "user") as! [PatrolLog]
    }
    
    //TODO: add filtered relationship fetchers to return CDFW boarding cards, activity logs, or nps boarding cards
    
    override class func setRelationships(json : JSON) -> Bool {
        for (index: String, model: JSON) in json {
            //First, get the right user model for the ID in the JSON.
            let uid = model["id"].stringValue
            let user = User(forPrimaryKey: uid)
            let agencyid = model["AgencyId"].stringValue
            NSLog(" \(model) \(agencyid) \(agencyid.dynamicType)")
            let agency = Agency(forPrimaryKey: agencyid)
            if agency != nil { user.agency = agency }
        }
        return true
    }
    
}
