//
//  VesselType.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class VesselType: EfinsModel {
    dynamic var name = ""
    
    var vessels: [Vessel] {
        return linkingObjectsOfClass("Vessel", forProperty: "vesselType") as [Vessel]
    }
}

