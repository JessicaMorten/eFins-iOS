//
//  dataSyncManager.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Alamofire

private let _mgr = DataSync()

class DataSync {
    
    
    class var manager: DataSync {
        return _mgr
    }
    
    func sync() {
        println("sync called");
    }
    
    
}
