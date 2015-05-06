//
//  ViolationFormTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/6/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class ViolationFormTableViewController: UITableViewController {

    
    @IBOutlet weak var enforcementActionTypeCell: RelationTableViewCell!
    @IBOutlet weak var violationTypeCell: RelationTableViewCell!

    @IBOutlet weak var saveButton: UIButton!
    
    var model:RLMObject?
    var label:String?
    var allowEditing = true
    var openTransaction = false
    var enforcementAction:EnforcementActionTaken {
        get {
            return self.model as! EnforcementActionTaken
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let realm = RLMRealm.defaultRealm()
        if self.model == nil {
            self.model = EnforcementActionTaken()
            let results = EnforcementActionType.allObjects().sortedResultsUsingProperty("createdAt", ascending: true)
            if results.count > 0 {
                self.enforcementAction.enforcementActionType = results.objectAtIndex(UInt(0)) as? EnforcementActionType
            }
        }
        self.enforcementActionTypeCell.setup(self.enforcementAction, allowEditing: self.allowEditing, property: "enforcementActionType", secondaryProperty: nil)
        self.violationTypeCell.setup(self.enforcementAction, allowEditing: allowEditing, property: "violationType", secondaryProperty: nil)
        setEditingState()
    }
    
    func setEditingState() {
        if allowEditing {
            self.saveButton.hidden = false
            self.enforcementActionTypeCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            self.navigationItem.rightBarButtonItem = nil
        } else {
            self.saveButton.hidden = true
            self.navigationItem.rightBarButtonItem = self.editButtonItem()
            self.navigationItem.rightBarButtonItem?.action = "startEditing"
            self.enforcementActionTypeCell.accessoryType = UITableViewCellAccessoryType.None
        }
        self.enforcementActionTypeCell.allowEditing = allowEditing
    }
    
    func startEditing() {
        self.allowEditing = true
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        self.openTransaction = true
        setEditingState()
    }
    
    @IBAction func unwindOneToMany(sender: UIStoryboardSegue) {
        println("unwindOneToMany:VesselFormTableViewController")
        let source = sender.sourceViewController as! OneToManyTableViewController
        source.cell?.updateValues()
    }
    
    @IBAction func save(sender: AnyObject) {
        if enforcementAction.violationType == nil {
            alert("Incomplete", "You must choose a violation type", self)
        } else if enforcementAction.enforcementActionType == nil {
            alert("Incomplete", "You must choose an action taken", self)
        } else {
            let realm = RLMRealm.defaultRealm()
            if self.openTransaction {
                
            } else {
                realm.beginWriteTransaction()
                realm.addObject(self.enforcementAction)
            }
            realm.commitWriteTransaction()
            self.performSegueWithIdentifier("UnwindCustomForm", sender: self)
        }
    }
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
}
