//
//  ActivityFormTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/8/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class ActivityFormTableViewController: UITableViewController {

    // location field
    @IBOutlet weak var locationTableCell: UITableViewCell!
    // TODO: immediately fetch location in background and spin indicator
    @IBOutlet weak var locationActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var locationSwitch: UISwitch!
    // date/time field
    @IBOutlet weak var dateTableCell: UITableViewCell!
    // free text comments
    @IBOutlet weak var remarksTextView: UITextView?
    // "observers"/wardens
    @IBOutlet weak var observersTableViewCell: RelationTableViewCell!
    // photos
    @IBOutlet weak var photosCell: UITableViewCell!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    // number of persons on board
    @IBOutlet weak var numPersonsOnBoardTextField: UITextField?
    @IBOutlet weak var numberOfPersonsOnBoardCell: UITableViewCell?

    
    @IBOutlet weak var saveButton: UIButton!
    
    var activity:Activity!

    // should be set by subclasses
    var activityType:String!
    var relationTableViewCells = [RelationTableViewCell]()
    var textViews = [UITextView]()
    var textFields = [UITextField]()
    
    var isNew = true
    var allowEditing = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.activityType == nil {
            NSException.raise("ActivityFormMisconfigured", format: "ActivityForm activityType var is not set", arguments: getVaList([]))
        }
        
        if self.activity == nil {
            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            activity = Activity()
            activity.type = activityType
            self.isNew = true
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel,
                target: self, action: "cancel")
            self.locationTableCell.textLabel?.text = "Include Location"
            activity.time = NSDate()
            if let user = (UIApplication.sharedApplication().delegate as! AppDelegate).getUser() {
                activity.users.addObject(user)
            }
            realm.addObject(self.activity)
            realm.commitWriteTransaction()
        } else {
            self.isNew = false
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "back")
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: "editButtonTapped")
            self.saveButton.hidden = true
            self.dateTableCell.accessoryType = UITableViewCellAccessoryType.None
            self.locationTableCell.textLabel?.text = "Location"
            self.locationSwitch.hidden = true
            self.remarksTextView?.editable = false
        }

        let formatter = getDateFormatter()
        dateTableCell.detailTextLabel?.text = formatter.stringFromDate(activity!.time)

        self.observersTableViewCell.setup(self.activity!, allowEditing: allowEditing, property: "freeTextCrew", secondaryProperty: "users")
        self.relationTableViewCells.append(observersTableViewCell)
        
        if let remarks = remarksTextView {
            remarks.text = activity.remarks
            self.textViews.append(remarks)
        }
        
        if let numPersonsField = self.numPersonsOnBoardTextField {
            numPersonsField.text = "\(activity.numPersonsOnBoard)"
            self.textFields.append(numPersonsField)
            if isNew == false {
                numPersonsField.enabled = false
            }
        }
        
        self.numberOfPersonsOnBoardCell?.textLabel?.text = "Number of Persons on Board"
        updateAccessoryTypes()
    }
    
    // MARK: Actions
    
    func cancel() {
        stopAllEditing()
        confirm("Cancel Record", "Are you sure you want to delete this record?", self, doCancel)
    }
    
    func doCancel() {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        realm.deleteObject(self.activity)
        realm.commitWriteTransaction()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func back() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func saveAction(sender: AnyObject) {
        // TODO: Validation (if any?)
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        realm.addObject(self.activity)
        realm.commitWriteTransaction()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // TODO: Implement location fetching
    @IBAction func locationSwitchValueChanged(sender: UISwitch) {
        if sender.on {
            self.locationActivityIndicator.hidden = false
            self.locationActivityIndicator.startAnimating()
        } else {
            self.locationActivityIndicator.hidden = true
        }
    }
    
    @IBAction func numPersonsOnBoardEditingEnded(sender: AnyObject) {
        if let n = self.numPersonsOnBoardTextField!.text.toInt() {
            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            self.activity.numPersonsOnBoard = n
            realm.commitWriteTransaction()
        }
    }
    
    @IBAction func personsOnBoardEditingDidBegin(sender: UITextField) {
        if sender.text == "0" {
            sender.text = ""
        }
    }
    
    // MARK: - Navigation
    
    @IBAction func unwindDatePicker(sender: UIStoryboardSegue) {
        let sourceViewController = sender.sourceViewController as! DatePickerTableViewController
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        activity?.time = sourceViewController.date!
        realm.commitWriteTransaction()
        let formatter = getDateFormatter()
        dateTableCell.detailTextLabel?.text = formatter.stringFromDate(activity!.time)
    }
    
    @IBAction func unwindOneToMany(sender: UIStoryboardSegue) {
        let source = sender.sourceViewController as! OneToManyTableViewController
        source.cell?.updateValues()
    }
    
    @IBAction func unwindCustomForm(sender: UIStoryboardSegue) {
        for cell in self.relationTableViewCells {
            cell.updateValues()
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let photosIndex = tableView.indexPathForCell(self.photosCell)!
        let datePickerIndex = tableView.indexPathForCell(self.dateTableCell)!
        if indexPath.section == photosIndex.section && indexPath.row == photosIndex.row {
            let storyboard = UIStoryboard(name: "PhotoList", bundle: nil)
            let controller = storyboard.instantiateInitialViewController() as! PhotosCollectionViewController
            controller.activity = self.activity
            controller.editing = self.allowEditing
            self.navigationController?.pushViewController(controller, animated: true)
        } else if indexPath.section == datePickerIndex.section && indexPath.row == datePickerIndex.row {
            let storyboard = UIStoryboard(name: "DatePicker", bundle: nil)
            let controller:DatePickerTableViewController = storyboard.instantiateInitialViewController() as! DatePickerTableViewController
            self.navigationController?.pushViewController(controller, animated: true)
            controller.date = activity!.time
        }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == "Add any relevant comments here..." {
            textView.text = ""
            textView.textColor = UIColor.blackColor()
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        if textView.text == "" {
            textView.text = "Add any relevant comments here..."
            textView.textColor = UIColor.lightGrayColor()
            self.activity?.remarks = ""
        } else {
            self.activity?.remarks = textView.text
        }
        realm.commitWriteTransaction()
        textView.resignFirstResponder()
    }
    
    @IBAction func tapRecognizer(sender:AnyObject) {
        stopAllEditing()
    }
    
    func stopAllEditing() {
        for field in self.textFields {
            field.endEditing(true)
        }
        for field in self.textViews {
            field.endEditing(true)
        }
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if cell is RelationTableViewCell {
            (cell as! RelationTableViewCell).displayDetails(self)
        }
    }
    
    
    @IBAction func takePhoto(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "PhotoList", bundle: nil)
        let controller = storyboard.instantiateInitialViewController() as! PhotosCollectionViewController
        controller.activity = self.activity
        controller.editing = self.allowEditing
        let alert = controller.getAlert()
        alert.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        alert.popoverPresentationController?.barButtonItem = self.cameraButton
        self.presentViewController(alert, animated: true) {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.photosCell.detailTextLabel?.text = "\(self.activity.photos.count)"
        updateAccessoryTypes()
        if let path = self.tableView.indexPathForSelectedRow() {
            self.tableView.deselectRowAtIndexPath(path, animated: true)
        }
    }
    
    func updateAccessoryTypes() {
        for cell in self.relationTableViewCells {
            cell.updateAccessoryType()
        }
    }

    func editButtonTapped() {
        enterEditMode()
    }
    
    func enterEditMode() {
        self.allowEditing = true
        self.updateRelationTableViewCellEditMode()
        for field in self.textFields {
            field.enabled = true
        }
        for field in self.textViews {
            field.editable = true
        }
        self.dateTableCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.leftBarButtonItem?.title = "Save and Exit"
    }
    
    func updateRelationTableViewCellEditMode() {
        for cell in self.relationTableViewCells {
            cell.allowEditing = self.allowEditing
        }
        self.updateAccessoryTypes()
    }
    
}
