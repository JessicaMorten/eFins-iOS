//
//  Agency.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class Agency: RLMObject {
    dynamic var localid = -1
    dynamic var serverid = -1
    dynamic var usn = -1
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    dynamic var name = ""
    dynamic var agencyVessels = RLMArray(objectClassName: AgencyVessel.className())
    dynamic var users = RLMArray(objectClassName: AgencyVessel.className())

    override class func primaryKey() -> String {
        return "localid"
    }
    
}





