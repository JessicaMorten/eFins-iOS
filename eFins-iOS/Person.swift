//
//  Person.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class Person: EfinsModel {
    dynamic var name = ""
    dynamic var license = ""
    dynamic var dateOfBirth = NSDate() //Optional
    dynamic var address = "" //Optional
    var crewActivities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "crew") as [Activity]
    }
    var captainActivities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "captain") as [Activity]
    }
}

