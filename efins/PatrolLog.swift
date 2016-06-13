//
//  PatrolLog.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class PatrolLog: EfinsModel {
    dynamic var user: User?
    dynamic var agencyVessel: AgencyVessel?
    dynamic var departurePort: Port?
    dynamic var date = NSDate()
    dynamic var wasClear = false
    dynamic var wasWindy = false
    dynamic var wasFoggy = false
    dynamic var wasCalm = false
    dynamic var wasRainy = false
    dynamic var hadSmallCraftAdvisory = false
    dynamic var hadGale = false
    dynamic var fuelToDate: Float = 0.0
    dynamic var fuelPurchased: Float = 0.0
    dynamic var lubeOil: Float = 0.0
    dynamic var portHoursBroughtForward = 0.0
    dynamic var starboardHoursBroughtForward: Float = 0.0
    dynamic var portLoggedHours: Float = 0.0
    dynamic var starboardLoggedHours: Float = 0.0
    dynamic var generatorHoursBroughtForward : Float = 0.0
    dynamic var generatorLoggedHours: Float = 0.0
    dynamic var outboardHoursBroughtForward: Float = 0.0
    dynamic var outboardLoggedHours : Float = 0.0
    dynamic var crew = RLMArray(objectClassName: User.className())
    dynamic var freeTextCrew = RLMArray(objectClassName: AgencyFreetextCrew.className())
    
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "patrolLog") as! [Activity]
    }

}