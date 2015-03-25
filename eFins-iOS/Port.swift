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
    
    var patrolLogs: [PatrolLog] {
        return linkingObjectsOfClass("PatrolLog", forProperty: "port") as [PatrolLog]
    }
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "port") as [Activity]
    }
}

