//
//  ContactType.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class ContactType: EfinsModel {
    dynamic var name = ""
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "contactType") as! [Activity]
    }
}

