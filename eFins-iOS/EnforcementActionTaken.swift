//
//  EnforcementActionTaken.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class EnforcementActionTaken: EfinsModel {
    dynamic var violationType: ViolationType?
    dynamic var code: RegulatoryCode?
    dynamic var enforcementActionType: EnforcementActionType?
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "enforcementActionsTaken") as [Activity]
    }
}

