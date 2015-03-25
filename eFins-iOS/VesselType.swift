//
//  VesselType.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class VesselType: RLMObject {
    dynamic var localid = -1
    dynamic var serverid = -1
    dynamic var usn = -1
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    dynamic var name = ""
    
    var vessels: [Vessel] {
        return linkingObjectsOfClass("Vessel", forProperty: "vesselType") as [Vessel]
    }
}

