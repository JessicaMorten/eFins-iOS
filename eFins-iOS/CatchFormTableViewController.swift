//
//  CatchFormTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/1/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class CatchFormTableViewController: UITableViewController, ItemForm {
    
    @IBOutlet weak var speciesCell: RelationTableViewCell!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var amountCell: UITableViewCell!
    
    var model:RLMObject?
    var label:String?
    var allowEditing = true
    var catch:Catch {
        get {
            return self.model as! Catch
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.model == nil {
            self.model = Catch()
            self.catch.amount = 0
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        } else {
            self.title = "Catch Details"
        }
        self.amountCell.textLabel?.text = "Amount (lbs)"
        displayValues()
        self.speciesCell.setup(self.catch, allowEditing: self.allowEditing, property: "species", secondaryProperty: nil)
        setEditingState()
    }
    
    func cancel() {
        confirm("Cancel", "Are you sure you want to cancel without saving this new Catch?", self) { () in
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func setEditingState() {
        if allowEditing {
            self.saveButton.hidden = false
            self.speciesCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
            self.navigationItem.rightBarButtonItem = nil
        } else {
            self.saveButton.hidden = true
            self.navigationItem.rightBarButtonItem = self.editButtonItem()
            self.navigationItem.rightBarButtonItem?.action = "startEditing"
            self.speciesCell.accessoryType = UITableViewCellAccessoryType.None
        }
        self.amountTextField.enabled = allowEditing
        self.speciesCell.allowEditing = allowEditing
        
    }
    
    func startEditing() {
        self.allowEditing = true
        setEditingState()
    }
    
    override func viewWillAppear(animated: Bool) {
        displayValues()
    }
    
    func displayValues() {
        self.amountTextField.text = "\(catch.amount)"
    }
    
    
    @IBAction func unwindOneToMany(sender: UIStoryboardSegue) {
        println("unwindOneToMany:VesselFormTableViewController")
        let source = sender.sourceViewController as! OneToManyTableViewController
        source.cell?.updateValues()
    }
    
    @IBAction func amountChanged(sender: UITextField) {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        if count(sender.text) > 0 {
            self.catch.amount = sender.text.toInt()!
        } else {
            self.catch.amount = 0
        }
        realm.commitWriteTransaction()
    }
    
    @IBAction func save(sender: AnyObject) {
        if catch.species == nil {
            alert("Incomplete", "You must choose a species", self)
        } else if catch.amount == 0 {
            alert("Incomplete", "Amount (lbs) must be greater than zero", self)
        } else {
            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            realm.addObject(self.catch)
            realm.commitWriteTransaction()
            self.performSegueWithIdentifier("UnwindCustomForm", sender: self)
        }
    }

    @IBAction func tap(sender: AnyObject) {
        self.amountTextField.endEditing(true)
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if cell is RelationTableViewCell {
            (cell as! RelationTableViewCell).displayDetails(self)
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
