//
//  RegulatoryCode.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class RegulatoryCode: EfinsModel {
    dynamic var name = ""
    var actionsTaken: [EnforcementActionTaken] {
        return linkingObjectsOfClass("EnforcementActionTaken", forProperty: "code") as! [EnforcementActionTaken]
    }
}

