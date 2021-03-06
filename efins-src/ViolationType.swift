//
//  ViolationType.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class ViolationType: EfinsModel {
    dynamic var name = ""
    dynamic var code = ""
    
    var actionsTaken: [EnforcementActionTaken] {
        return linkingObjectsOfClass("EnforcementActionTaken", forProperty: "violationType") as! [EnforcementActionTaken]
    }
}

