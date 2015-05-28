//
//  CDFWCommBoardingCardTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/1/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class CDFWCommBoardingCardTableViewController: ActivityFormTableViewController, UITextViewDelegate {
    
    @IBOutlet weak var vesselTableViewCell: RelationTableViewCell!
    @IBOutlet weak var crewCell: RelationTableViewCell!
    @IBOutlet weak var captainCell: RelationTableViewCell!
    @IBOutlet weak var activityCell: RelationTableViewCell!
    @IBOutlet weak var catchesCell: RelationTableViewCell!
    @IBOutlet weak var citationsCell: RelationTableViewCell!
    @IBOutlet weak var categoryOfBoardingCell: UITableViewCell!
    
    override func viewDidLoad() {
        self.activityType = Activity.Types.CDFW_COMM
        super.viewDidLoad()
        if self.isNew {
            self.categoryOfBoardingCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        } else {
            self.categoryOfBoardingCell.accessoryType = UITableViewCellAccessoryType.None
        }
        self.vesselTableViewCell.setup(self.activity!, allowEditing: allowEditing, property: "vessel", secondaryProperty: nil)
        self.vesselTableViewCell.setCustomForm(UIStoryboard(name: "VesselForm", bundle: nil), identifier: "VesselForm")
        self.crewCell.setup(self.activity!, allowEditing: allowEditing, property: "crew", secondaryProperty: nil)
        self.crewCell.setCustomForm(UIStoryboard(name: "PersonForm", bundle: nil), identifier: "PersonForm")
        self.captainCell.setup(self.activity!, allowEditing: allowEditing, property: "captain", secondaryProperty: nil)
        self.captainCell.setCustomForm(UIStoryboard(name: "PersonForm", bundle:nil), identifier: "PersonForm")
        self.catchesCell.label = "Species"
        self.catchesCell.skipSearch = true
        self.catchesCell.setup(self.activity!, allowEditing: allowEditing, property: "catches", secondaryProperty: nil)
        self.catchesCell.setCustomForm(UIStoryboard(name: "CatchForm", bundle:nil), identifier: "CatchForm")
        self.activityCell.setup(self.activity!, allowEditing: allowEditing, property: "action", secondaryProperty: nil)
        self.citationsCell.skipSearch = true
        self.citationsCell.setCustomForm(UIStoryboard(name: "ViolationForm", bundle: nil), identifier: "ViolationForm")
        self.citationsCell.setup(self.activity!, allowEditing: allowEditing, property: "enforcementActionsTaken", secondaryProperty: nil)
        self.categoryOfBoardingCell.detailTextLabel?.text = activity!.categoryOfBoarding

        self.relationTableViewCells.append(self.vesselTableViewCell)
        self.relationTableViewCells.append(self.crewCell)
        self.relationTableViewCells.append(self.captainCell)
        self.relationTableViewCells.append(self.activityCell)
        self.relationTableViewCells.append(self.catchesCell)
        self.relationTableViewCells.append(self.citationsCell)
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if self.activity.patrolLog != nil {
                return 3
            } else {
                return super.tableView(tableView, numberOfRowsInSection: section)
            }
        } else {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }

    
    // MARK: Actions
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if self.isNew == false {
            if sender is UITableViewCell && (sender as! UITableViewCell) == self.categoryOfBoardingCell && allowEditing != true {
                return false
            }
        }
        return true
    }
    
    @IBAction func unwindBoardingType(sender:UIStoryboardSegue) {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        self.activity!.categoryOfBoarding = (sender.sourceViewController as! BoardingTypeTableViewController).selection
        realm.commitWriteTransaction()
        self.categoryOfBoardingCell.detailTextLabel?.text = activity!.categoryOfBoarding
    }
    
    override func enterEditMode() {
        super.enterEditMode()
        self.categoryOfBoardingCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
    }
    
}
