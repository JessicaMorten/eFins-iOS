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
    dynamic var agencyVessels = RLMArray(objectClassName: AgencyVessel.className())
    
    var users: [User] {
        return linkingObjectsOfClass("User", forProperty: "agency") as! [User]
    }
    
}





