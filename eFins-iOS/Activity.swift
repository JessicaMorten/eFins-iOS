//
//  ActivityLog.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class Activity: EfinsModel{
    dynamic var type = "cdfwCommercialBoardingCard" //or "npsRecreationalBoardingCard" or "activityLog".  this "subclasses" the Activity model.
    dynamic var freeTextCrew = RLMArray(objectClassName: FreeTextCrew.className()) // Crew of the fishing Vessel associated with this Activity
    dynamic var users = RLMArray(objectClassName: User.className()) // Agency users associated
    dynamic var catches = RLMArray(objectClassName: Catch.className())  // Catches by the Vessel
    dynamic var port: Port? // Port the Vessel left from
    dynamic var vessel: Vessel?  // the fishing vessel (NOT the AgencyVessel)
    dynamic var fishery: Fishery?
    dynamic var action: Action? // CDFW field; not sure what it is
    dynamic var captain: Person? //Captain of the fishing vessel, not the agency vessel
    dynamic var person: Person? //Activity logs have a person associated, but not the other types
    dynamic var crew = RLMArray(objectClassName: Person.className()) // Crew of the fishing vessel
    dynamic var photos = RLMArray(objectClassName: Photo.className())
    dynamic var enforcementActionsTaken = RLMArray(objectClassName: EnforcementActionTaken.className())
    
    var patrolLog: PatrolLog {
        let logs = linkingObjectsOfClass("PatrolLog", forProperty: "activities")
        return logs[0] as! PatrolLog
    }
    
    dynamic var time = NSDate()
    dynamic var remarks = ""
    dynamic var latitude = 0
    dynamic var longitude = 0
    dynamic var locationManuallyEntered = false
    dynamic var contactType: ContactType?  // this is a NPS field

}

