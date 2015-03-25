//
//  dataSyncManager.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Alamofire
import Realm

private let _mgr = DataSync()

class DataSync {
    
    class var manager: DataSync {
        return _mgr
    }
    
    func sync() {
        println("sync called");
        let dRealm = self.defaultRealm()
        dRealm.beginWriteTransaction()
        // In real life all agency objects will be created on the server.  this is a placeholder test to make sure we can write to Realm.
        Agency.createInDefaultRealmWithObject([
            "name": "KGB"
        ])
        dRealm.commitWriteTransaction()
    }
    
    func defaultRealm() -> RLMRealm {
        return RLMRealm.defaultRealm()
    }
    
}
