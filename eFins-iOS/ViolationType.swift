//
//  ViolationType.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class ViolationType: RLMObject {
    dynamic var localid = -1
    dynamic var serverid = -1
    dynamic var usn = -1
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    dynamic var name = ""
    var actionsTaken: [EnforcementActionTaken] {
        return linkingObjectsOfClass("EnforcementActionTaken", forProperty: "violationType") as [EnforcementActionTaken]
    }
}

