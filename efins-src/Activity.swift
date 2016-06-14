//
//  ActivityLog.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class Activity: EfinsModel {
    dynamic var type = "cdfwCommercialBoardingCard" //or one of the other 'Types' as defined below.  This "subclasses" the Activity model.
    dynamic var freeTextCrew = RLMArray(objectClassName: FreeTextCrew.className()) // Crew of the observing vessel associated with this Activity (Basically wardens that aren't iPad users)
    dynamic var users = RLMArray(objectClassName: User.className()) // Agency users associated
    dynamic var photos = RLMArray(objectClassName: Photo.className())
    dynamic var catches = RLMArray(objectClassName: Catch.className())
    dynamic var port: Port? // Port the Vessel left from
    dynamic var vessel: Vessel?  // the fishing vessel (NOT the AgencyVessel)
    dynamic var fishery: Fishery?
    dynamic var action: Action? // CDFW field; not sure what it is
    dynamic var captain: Person? //Captain of the fishing vessel, not the agency vessel
    dynamic var person: Person? //Activity logs have a person associated, but not the other types
    dynamic var patrolLog: PatrolLog?
    dynamic var crew = RLMArray(objectClassName: Person.className()) // Crew of the fishing vessel
    dynamic var enforcementActionsTaken = RLMArray(objectClassName: EnforcementActionTaken.className())
    dynamic var numPersonsOnBoard:Int = 0
    dynamic var time = NSDate()
    dynamic var remarks = ""
    dynamic var latitude: Double = 35.0
    dynamic var longitude: Double = -122.0
    dynamic var locationManuallyEntered = false
    dynamic var contactType: ContactType?  // this is a NPS field
    dynamic var categoryOfBoarding:String = "Neutral"
    
    struct Types {
        static let CDFW_REC = "cdfwRecreationalBoardingCard"
        static let CDFW_COMM = "cdfwCommercialBoardingCard"
        static let NPS = "npsContactCard"
        static let LOG = "activityLog"
    }
    
}
