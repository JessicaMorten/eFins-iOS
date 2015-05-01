//
//  Agency.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class Agency: EfinsModel {
    dynamic var name = ""
    
    var users: [User] {
        return linkingObjectsOfClass("User", forProperty: "agency") as! [User]
    }
    
    var agencyVessels: [AgencyVessel] {
        return linkingObjectsOfClass("AgencyVessel", forProperty: "agency") as! [AgencyVessel]
    }
    
}





