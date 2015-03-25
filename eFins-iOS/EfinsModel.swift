//
//  efinsModel.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/25/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class EfinsModel : RLMObject {
    dynamic var localid =  NSUUID.init().UUIDString
    dynamic var serverid = -1
    dynamic var usn = -1
    dynamic var createdAt = NSDate()
    dynamic var updatedAt = NSDate()
}
