//
//  NPSContactTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/7/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class NPSContactTableViewController: ActivityFormTableViewController {
    
    @IBOutlet weak var vesselTableViewCell: RelationTableViewCell!
    @IBOutlet weak var captainCell: RelationTableViewCell!
    @IBOutlet weak var citationsCell: RelationTableViewCell!
    @IBOutlet weak var contactTypeCell: RelationTableViewCell!
    
    override func viewDidLoad() {
        activityType = Activity.Types.NPS
        super.viewDidLoad()
        self.vesselTableViewCell.setup(self.activity!, allowEditing: allowEditing, property: "vessel", secondaryProperty: nil)
        self.vesselTableViewCell.setCustomForm(UIStoryboard(name: "VesselForm", bundle: nil), identifier: "VesselForm")
        self.captainCell.setup(self.activity!, allowEditing: allowEditing, property: "captain", secondaryProperty: nil)
        self.captainCell.setCustomForm(UIStoryboard(name: "PersonForm", bundle:nil), identifier: "PersonForm")
        self.citationsCell.skipSearch = true
        self.citationsCell.setCustomForm(UIStoryboard(name: "ViolationForm", bundle: nil), identifier: "ViolationForm")
        self.citationsCell.setup(self.activity!, allowEditing: allowEditing, property: "enforcementActionsTaken", secondaryProperty: nil)
        self.contactTypeCell.setup(self.activity!, allowEditing: allowEditing, property: "contactType", secondaryProperty: nil)

        self.relationTableViewCells.append(self.vesselTableViewCell)
        self.relationTableViewCells.append(self.captainCell)
        self.relationTableViewCells.append(self.citationsCell)
        self.relationTableViewCells.append(self.contactTypeCell)
    }
}
