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
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    dynamic var name = ""
    var users: [User] {
        return linkingObjectsOfClass("User", forProperty: "agency") as [User]
    }
    
    override class func primaryKey() -> String {
        return "localid"
    }
    
}





