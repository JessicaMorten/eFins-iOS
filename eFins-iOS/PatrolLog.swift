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
    dynamic var fuelToDate = 0
    dynamic var fuelPurchased = 0
    dynamic var lubeOil = 0
    dynamic var portHoursBroughtForward = 0
    dynamic var starboardHoursBroughtForward = 0
    dynamic var portLoggedHours = 0
    dynamic var starboardLoggedHours = 0
    dynamic var generatorHoursBroughtForward = 0
    dynamic var generatorLoggedHours = 0
    dynamic var outboardHoursBroughtForward = 0
    dynamic var outboardLoggedHours = 0
    dynamic var freeTextCrew = RLMArray(objectClassName: FreeTextCrew.className())
    dynamic var activities = RLMArray(objectClassName: Activity.className())
    dynamic var freeTextOthersAboard = ""
}