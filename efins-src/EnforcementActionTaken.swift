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
    dynamic var enforcementActionType: EnforcementActionType?
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "enforcementActionsTaken") as! [Activity]
    }
    
    var name:String {
        // always required
        if let e = enforcementActionType {
            if let v = violationType {
                return "\(e.name) - \(v.name)"
            } else {
                return "\(e.name) - Unknown violation type"
            }
        } else {
            return "Invalid"
        }
    }
}

