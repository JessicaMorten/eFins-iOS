//
//  CDFWRecContactTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 4/30/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class CDFWRecContactTableViewController: ActivityFormTableViewController {
    
    override func viewDidLoad() {
        self.activityType = Activity.Types.CDFW_REC
        super.viewDidLoad()
    }
}
