//
//  Photo.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class Photo: RLMObject {
    dynamic var localid = -1
    dynamic var serverid = -1
    dynamic var usn = -1
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    dynamic var originalUrl = ""
    dynamic var latitude = 0
    dynamic var longitude = 0
    dynamic var lowResolution = NSData()
    dynamic var originalBlog = NSData()
    
    var activities: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "photos") as [Activity]
    }
    // TODO: add relationship filters for different kinds of activity
}
