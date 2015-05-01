//
//  Port.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class Port: EfinsModel {
    dynamic var name = ""
    dynamic var patrolLogs = RLMArray(objectClassName: PatrolLog.className())
    
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "departurePort") as! [Activity]
    }
}

