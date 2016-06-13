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
    var person:Person {
        get {
            return self.model as! Person
        }
    }
    
    var inWriteTransaction = false
    
    
    
    func beginWriteTransaction() {
        if self.inWriteTransaction {
            NSException.raise("Realm Transaction Error", format: "Tried to begin transaction, but one is open", arguments: getVaList([]))
        }
        self.inWriteTransaction = true
        RLMRealm.defaultRealm().beginWriteTransaction()
    }
    
    func commitWriteTransaction() {
        if self.inWriteTransaction {
            self.person.updatedAt = NSDate()
            self.person.dirty = true
            RLMRealm.defaultRealm().commitWriteTransaction()
            self.inWriteTransaction = false
        } else {
            if self.inWriteTransaction {
                NSException.raise("Realm Transaction Error", format: "Tried to commit transaction, but none open", arguments: getVaList([]))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.model == nil {
            self.model = Person()
            self.person.name = self.label!
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
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
    
    func cancel() {
        confirm("Cancel", message: "Are you sure you want to cancel without saving this new Person?", view: self) { () in
            self.navigationController?.popViewControllerAnimated(true)
        }
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
        self.beginWriteTransaction()
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
        if person.name.characters.count < 1 && person.license.characters.count < 1 {
            alert("Incomplete", message: "You must enter a name or license", view: self)
        } else {
            let realm = RLMRealm.defaultRealm()
            if self.inWriteTransaction{
                print("open transaction")
            } else {
                self.beginWriteTransaction()
                realm.addObject(person)
            }
            self.commitWriteTransaction()
            self.allowEditing = false
            self.performSegueWithIdentifier("UnwindCustomForm", sender: self)
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
