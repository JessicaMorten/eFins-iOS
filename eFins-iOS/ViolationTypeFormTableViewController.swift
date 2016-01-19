//
//  ViolationTypeFormTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/6/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class ViolationTypeFormTableViewController: UITableViewController, ItemForm {

    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var codeCell: UITableViewCell!
    
    var model:RLMObject?
    var label:String?
    var allowEditing = true
    var violationType:ViolationType {
        get {
            return self.model as! ViolationType
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
            self.violationType.updatedAt = NSDate()
            self.violationType.dirty = true
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
            self.model = ViolationType()
            if let name = self.label {
                violationType.name = name
            }
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        } else {
            self.title = "Violation Type Details"
        }
        displayValues()
        setEditingState()
        self.nameCell.textLabel?.text = "Violation Type"
        self.codeCell.textLabel?.text = "Code"
    }
    
    func cancel() {
        confirm("Cancel", message: "Are you sure you want to cancel without saving this new Violation Type?", view: self) { () in
            self.navigationController?.popViewControllerAnimated(true)
        }
    }

    func setEditingState() {
        if allowEditing {
            self.saveButton.hidden = false
            self.navigationItem.rightBarButtonItem = nil
        } else {
            self.saveButton.hidden = true
            self.navigationItem.rightBarButtonItem = self.editButtonItem()
            self.navigationItem.rightBarButtonItem?.action = "startEditing"
        }
        self.nameField.enabled = allowEditing
        self.codeField.enabled = allowEditing
        
    }
    
    func startEditing() {
        self.allowEditing = true
        setEditingState()
    }
    
    override func viewWillAppear(animated: Bool) {
        displayValues()
    }
    
    func displayValues() {
        self.nameField.text = violationType.name
        self.codeField.text = violationType.code
    }
    
    @IBAction func nameChanged(sender: UITextField) {
        self.violationType.beginWriteTransaction()
        self.violationType.name = sender.text!
        self.violationType.commitWriteTransaction()
    }

    @IBAction func codeChanged(sender: UITextField) {
        self.violationType.beginWriteTransaction()
        self.violationType.code = sender.text!
        self.violationType.commitWriteTransaction()
    }
    
    @IBAction func save(sender: AnyObject) {
        if violationType.name.characters.count < 1 {
            alert("Incomplete", message: "You must specify a violation type", view: self)
        } else {
            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            realm.addObject(self.violationType)
            self.violationType.dirty = true
            realm.commitWriteTransaction()
            self.performSegueWithIdentifier("UnwindCustomForm", sender: self)
        }
    }
    
    @IBAction func tap(sender: AnyObject) {
        self.codeField.endEditing(true)
        self.nameField.endEditing(true)
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
