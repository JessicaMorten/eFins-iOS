//
//  User.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class User: RLMObject {
    dynamic var localid = -1
    dynamic var serverid = -1
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
    dynamic var email = ""
    dynamic var name = ""
    dynamic var approved = false
    dynamic var secrettoken = ""
    dynamic var emailconfirmed = false
    dynamic var agency: Agency?
}
