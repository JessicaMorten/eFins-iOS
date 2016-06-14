//
//  Species.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

class Species: EfinsModel {
    dynamic var name = ""
    
    var catches: [Catch] {
        return linkingObjectsOfClass("Catch", forProperty: "species") as! [Catch]
    }
}

