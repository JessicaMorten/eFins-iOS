//
//  EnforcementActionTaken.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class EnforcementActionTaken: RLMObject {
    dynamic var localid = -1
    dynamic var serverid = -1
    dynamic var usn = -1
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    dynamic var violationType: ViolationType?
    dynamic var code: RegulatoryCode?
    dynamic var enforcementActionType: EnforcementActionType?
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "enforcementActionsTaken") as [Activity]
    }
}

