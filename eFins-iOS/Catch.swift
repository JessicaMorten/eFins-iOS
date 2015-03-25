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
    var activity: Activity {
        let cards = linkingObjectsOfClass("Activity", forProperty: "catches")
        return cards[0] as Activity
    }
}

