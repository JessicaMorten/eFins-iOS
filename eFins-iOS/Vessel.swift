//
//  Vessel.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class Vessel: EfinsModel {
    dynamic var name = ""
    dynamic var registration = ""
    dynamic var fgNumber = ""
    dynamic var vesselType: VesselType?
    
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "vessel") as! [Activity]
    }
}
