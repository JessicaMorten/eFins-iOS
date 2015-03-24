//
//  Catch.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class Catch: RLMObject {
    dynamic var localid = -1
    dynamic var serverid = -1
    dynamic var usn = -1
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    dynamic var species: Species?
    dynamic var amount = 0
    var activity: Activity {
        let cards = linkingObjectsOfClass("Activity", forProperty: "catches")
        return cards[0] as Activity
    }
}

