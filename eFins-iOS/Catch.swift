//
//  Catch.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class Catch: EfinsModel {
    dynamic var species: Species?
    dynamic var amount = 0
    
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "catches") as! [Activity]
    }

}

