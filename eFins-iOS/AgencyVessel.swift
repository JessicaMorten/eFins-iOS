//
//  AgencyVessel.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class AgencyVessel: EfinsModel {
    dynamic var name = ""
    
    var agency: Agency {
        let agencies = linkingObjectsOfClass("Agency", forProperty: "agencyVessels") as! [Agency]
        return agencies[0]
    }
    
    var patrolLogs: [PatrolLog] {
        return linkingObjectsOfClass("PatrolLog", forProperty: "agencyVessel") as! [PatrolLog]
    }
    
}





