//
//  PersonFormTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 4/21/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class PersonFormTableViewController: UITableViewController, ItemForm, UITextFieldDelegate {
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var licenseCell: UITableViewCell!
    @IBOutlet weak var licenseField: UITextField!
    @IBOutlet weak var dobCell: UITableViewCell!
    @IBOutlet weak var addressCell: UITableViewCell!
    @IBOutlet weak var addressTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!

    var model:RLMObject?
    var label:String?
    var allowEditing = true
    var openTransaction = false
    var person:Person {
        get {
            return self.model as! Person
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.model == nil {
            self.model = Person()
            self.person.name = self.label!
        } else {
            self.title = "Details"
        }
        self.nameCell.textLabel?.text = "Name"
        self.licenseCell.textLabel?.text = "License"
        displayValues()
        setEditingState()
    }
    
    func setEditingState() {
        if allowEditing {
            self.saveButton.hidden = false
        } else {
            self.saveButton.hidden = true
            self.navigationItem.rightBarButtonItem = self.editButtonItem()
            self.navigationItem.rightBarButtonItem?.action = "startEditing"
        }
        self.nameField.hidden = !allowEditing
        self.licenseField.hidden = !allowEditing
        self.addressTextView.editable = allowEditing
    }
    
    func startEditing() {
        self.allowEditing = true
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        self.openTransaction = true
        setEditingState()
    }

    override func viewWillAppear(animated: Bool) {
        displayValues()
    }
    
    @IBAction func nameChanged(sender: UITextField) {
        self.person.name = sender.text
    }

    @IBAction func licenseChanged(sender: UITextField) {
        self.person.license = sender.text
    }
    
    func displayValues() {
        self.nameField.text = person.name
        self.licenseField.text = person.license
        self.dobCell.detailTextLabel?.text = "\(person.dateOfBirth)"
        self.addressTextView.text = person.address
        if !allowEditing {
            self.nameCell.detailTextLabel?.text = person.name
            self.licenseCell.detailTextLabel?.text = person.license
        } else {
            self.nameCell.detailTextLabel?.text = " "
            self.licenseCell.detailTextLabel?.text = " "
        }
    }
    
    @IBAction func unwindDatePicker(sender: UIStoryboardSegue) {
        let sourceViewController = sender.sourceViewController as! DayDatePickerTableViewController
        person.dateOfBirth = sourceViewController.date!
        let formatter = getDateFormatter()
        dobCell.detailTextLabel?.text = formatter.stringFromDate(person.dateOfBirth)
    }

    
    @IBAction func save(sender: AnyObject) {
        if count(person.name) < 1 && count(person.license) < 1 {
            alert("Incomplete", "You must enter a name or license", self)
        } else {
            let realm = RLMRealm.defaultRealm()
            if self.openTransaction {
                
            } else {
                realm.beginWriteTransaction()
                realm.addObject(person)
            }
            realm.commitWriteTransaction()
            self.performSegueWithIdentifier("UnwindPicker", sender: self)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 2 && self.allowEditing {
            let storyboard = UIStoryboard(name: "DayDatePicker", bundle: nil)
            let controller:DayDatePickerTableViewController = storyboard.instantiateInitialViewController() as! DayDatePickerTableViewController
            self.navigationController?.pushViewController(controller, animated: true)
            controller.date = person.dateOfBirth
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }

}
