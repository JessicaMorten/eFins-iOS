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
        self.nameCell.detailTextLabel?.text = " "
        self.licenseCell.detailTextLabel?.text = " "
        displayValues()
        setEditingState()
    }
    
    func setEditingState() {
        if allowEditing {
            self.saveButton.hidden = false
            self.dobCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        } else {
            self.saveButton.hidden = true
            self.navigationItem.rightBarButtonItem = self.editButtonItem()
            self.navigationItem.rightBarButtonItem?.action = "startEditing"
            self.dobCell.accessoryType = UITableViewCellAccessoryType.None
        }
        self.nameField.enabled = allowEditing
        self.licenseField.enabled = allowEditing
        self.addressTextView.editable = allowEditing
    }
    
    func startEditing() {
        self.navigationItem.rightBarButtonItem = nil
        self.allowEditing = true
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        self.openTransaction = true
        setEditingState()
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == self.nameField) {
            self.licenseField.becomeFirstResponder()
        }
        return true
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
    
    func textViewDidBeginEditing(textView: UITextView) {
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.person.address = textView.text
        textView.resignFirstResponder()
    }
    
    @IBAction func tapRecognizer(sender:AnyObject) {
        self.hideNotesKeyboard()
    }
    
    func hideNotesKeyboard() {
        self.addressTextView.endEditing(true)
    }

    
    func displayValues() {
        self.nameField.text = person.name
        self.licenseField.text = person.license
        let formatter = getDayDateFormatter()
        self.dobCell.detailTextLabel?.text = formatter.stringFromDate(person.dateOfBirth)

        self.addressTextView.text = person.address
        
//        if allowEditing == false {
//            self.nameCell.detailTextLabel?.text = person.name
//            self.licenseCell.detailTextLabel?.text = person.license
//        } else {
//            self.nameCell.detailTextLabel?.text = " "
//            self.licenseCell.detailTextLabel?.text = " "
//        }
    }
    
    @IBAction func unwindDatePicker(sender: UIStoryboardSegue) {
        let sourceViewController = sender.sourceViewController as! DayDatePickerTableViewController
        person.dateOfBirth = sourceViewController.date!
        let formatter = getDayDateFormatter()
        dobCell.detailTextLabel?.text = formatter.stringFromDate(person.dateOfBirth)
    }

    
    @IBAction func save(sender: AnyObject) {
        self.nameField.endEditing(true)
        self.licenseField.endEditing(true)
        if count(person.name) < 1 && count(person.license) < 1 {
            alert("Incomplete", "You must enter a name or license", self)
        } else {
            let realm = RLMRealm.defaultRealm()
            if self.openTransaction {
                println("open transaction")
            } else {
                realm.beginWriteTransaction()
                realm.addObject(person)
            }
            realm.commitWriteTransaction()
            self.allowEditing = false
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
