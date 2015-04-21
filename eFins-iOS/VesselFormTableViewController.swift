//
//  VesselFormTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 4/17/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class VesselFormTableViewController: UITableViewController, ItemForm, UITextFieldDelegate {

    @IBOutlet weak var nameCell: UITableViewCell!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var registrationCell: UITableViewCell!
    @IBOutlet weak var registrationTextField: UITextField!
    @IBOutlet weak var fgNumberCell: UITableViewCell!
    @IBOutlet weak var fgNumberTextField: UITextField!
    @IBOutlet weak var vesselTypeCell: RelationTableViewCell!
    @IBOutlet weak var saveButton: UIButton!
    
    var model:RLMObject?
    var label:String?
    var allowEditing = true
    var vessel:Vessel {
        get {
            return self.model as! Vessel
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.model == nil {
            self.model = Vessel()
            self.vessel.name = self.label!
        }
        self.nameCell.textLabel?.text = "Vessel Name"
        self.registrationCell.textLabel?.text = "Registration"
        self.fgNumberCell.textLabel?.text = "Fish & Game Number"
        displayValues()
        self.vesselTypeCell.setup(self.vessel, allowEditing: self.allowEditing, property: "vesselType", secondaryProperty: nil)
        
        if allowEditing {
            self.saveButton.hidden = false
        } else {
            self.saveButton.hidden = true
        }
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        displayValues()
    }
    
    func displayValues() {
        self.nameTextField.text = vessel.name
        self.registrationTextField.text = vessel.registration
        self.fgNumberTextField.text = vessel.fgNumber
    }
    

    @IBAction func unwindOneToMany(sender: UIStoryboardSegue) {
        println("unwindOneToMany:VesselFormTableViewController")
        let source = sender.sourceViewController as! OneToManyTableViewController
        source.cell?.updateValues()
    }
    
    @IBAction func nameChanged(sender: UITextField) {
        self.vessel.name = sender.text
    }
    
    @IBAction func registrationChanged(sender: UITextField) {
        self.vessel.registration = sender.text
    }
    
    @IBAction func fgNumberChanged(sender: UITextField) {
        self.vessel.fgNumber = sender.text
    }
    
    @IBAction func save(sender: AnyObject) {
        println(vessel.name)
        println(vessel.registration)
        if count(vessel.name) < 1 && count(vessel.registration) < 1 {
            alert("Incomplete", "You must enter a vessel name or registration", self)
        } else {
            println("save")
            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            realm.addObject(self.vessel)
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
