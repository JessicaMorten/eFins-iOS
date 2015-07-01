//
//  ActivityLogTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class ActivityLogTableViewController: ActivityFormTableViewController, UITextViewDelegate {

    @IBOutlet weak var vesselTableViewCell: RelationTableViewCell!
    @IBOutlet weak var crewCell: RelationTableViewCell!
    
    override func viewDidLoad() {
        self.activityType = Activity.Types.LOG
        super.viewDidLoad()
        self.vesselTableViewCell.setup(self.activity!, allowEditing: allowEditing, property: "vessel", secondaryProperty: nil)
        self.vesselTableViewCell.setCustomForm(UIStoryboard(name: "VesselForm", bundle: nil), identifier: "VesselForm")
        self.crewCell.setup(self.activity!, allowEditing: allowEditing, property: "crew", secondaryProperty: nil)
        self.crewCell.setCustomForm(UIStoryboard(name: "PersonForm", bundle: nil), identifier: "PersonForm")
        
        self.relationTableViewCells.append(self.vesselTableViewCell)
        self.relationTableViewCells.append(self.crewCell)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if self.activity.patrolLog != nil {
                return 2
            } else {
                return super.tableView(tableView, numberOfRowsInSection: section)
            }
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }
    
}
