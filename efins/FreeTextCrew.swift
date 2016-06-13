//
//  FreeTextCrew.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class FreeTextCrew: EfinsModel {
    dynamic var name = ""
    
    var patrolLogs: [PatrolLog] {
        return linkingObjectsOfClass("PatrolLog", forProperty: "freeTextCrew") as! [PatrolLog]
    }
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "freeTextCrew") as! [Activity]
    }
    
    //TODO_ add relationship accessors for particular types of activities
}