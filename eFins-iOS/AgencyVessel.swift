//
//  AgencyVessel.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class AgencyVessel: RLMObject {
    dynamic var localid = -1
    dynamic var serverid = -1
    dynamic var usn = -1
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    dynamic var name = ""
    
    var agency: Agency {
        let agencies = linkingObjectsOfClass("Agency", forProperty: "agencyVessels") as [Agency]
        return agencies[0]
    }
    
    var patrolLogs: [PatrolLog] {
        return linkingObjectsOfClass("PatrolLog", forProperty: "agencyVessel") as [PatrolLog]
    }
    
    override class func primaryKey() -> String {
        return "localid"
    }
}





