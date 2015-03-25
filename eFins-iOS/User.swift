//
//  User.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class User: EfinsModel {
    dynamic var email = ""
    dynamic var name = ""
    dynamic var approved = false
    dynamic var secrettoken = ""
    dynamic var emailconfirmed = false
    
    //Belongs-to relationships
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "user") as [Activity]
    }
    
    var patrolLogs: [PatrolLog] {
        return linkingObjectsOfClass("PatrolLog", forProperty: "user") as [PatrolLog]
    }
    
    var agency: Agency {
        let agencies = linkingObjectsOfClass("Agency", forProperty: "users")
        return agencies[0] as Agency
    }
    
    //TODO: add filtered relationship fetchers to return CDFW boarding cards, activity logs, or nps boarding cards
    
}
