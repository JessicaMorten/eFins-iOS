//
//  ActivityLogTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class ActivityLogTableViewController: UITableViewController, UITextViewDelegate {

    @IBOutlet weak var locationTableCell: UITableViewCell!
    // TODO: immediately fetch location in background and spin indicator
    @IBOutlet weak var locationActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var dateTableCell: UITableViewCell!
    @IBOutlet weak var remarksTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var observersTableViewCell: RelationTableViewCell!
    @IBOutlet weak var vesselTableViewCell: RelationTableViewCell!
    @IBOutlet weak var crewCell: RelationTableViewCell!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var photosCell: UITableViewCell!

    var activity:Activity?
    var isNew = true
    var allowEditing = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.activity != nil {
            self.isNew = false
        }
        
        let realm = RLMRealm.defaultRealm()
        if self.isNew {
            activity = Activity()
            // TODO: Make an actual type
            activity?.type = "activityLog"
//            let predicate = NSPredicate(format: "color = %@ AND name BEGINSWITH %@", "tan", "B")
//            let type = ContactType.objectsWithPredicate(predicate).firstObject()
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel,
                target: self, action: "cancel")
            self.locationTableCell.textLabel?.text = "Include Location"
            activity?.time = NSDate()
            let formatter = getDateFormatter()
            dateTableCell.detailTextLabel?.text = formatter.stringFromDate(activity!.time)
        } else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "back")
            self.navigationItem.rightBarButtonItem = nil
            self.saveButton.hidden = true
            let formatter = getDateFormatter()
            dateTableCell.detailTextLabel?.text = formatter.stringFromDate(activity!.time)
            self.dateTableCell.accessoryType = UITableViewCellAccessoryType.None
            self.remarksTextView.text = activity?.remarks
            self.locationTableCell.textLabel?.text = "Location"
            self.locationSwitch.hidden = true
        }
        self.observersTableViewCell.setup(self.activity!, allowEditing: allowEditing, property: "freeTextCrew", secondaryProperty: "users")
        self.vesselTableViewCell.setup(self.activity!, allowEditing: allowEditing, property: "vessel", secondaryProperty: nil)
        self.vesselTableViewCell.setCustomForm(UIStoryboard(name: "VesselForm", bundle: nil), identifier: "VesselForm")
        self.crewCell.setup(self.activity!, allowEditing: allowEditing, property: "crew", secondaryProperty: nil)
        self.crewCell.setCustomForm(UIStoryboard(name: "PersonForm", bundle: nil), identifier: "PersonForm")
    }
    
    // MARK: Actions
    
    // TODO: delete model on cancel
    func cancel() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func back() {
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
    
    @IBAction func saveAction(sender: AnyObject) {
        // TODO: Validation (if any?)
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        realm.addObject(self.activity)
        realm.commitWriteTransaction()
        self.observersTableViewCell.updateRecentValuesCounts()
        self.vesselTableViewCell.updateRecentValuesCounts()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    // MARK: - Navigation

//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        // Get the new view controller using [segue destinationViewController].
//        // Pass the selected object to the new view controller.
//        let controller = segue.destinationViewController
//    }


    @IBAction func unwindDatePicker(sender: UIStoryboardSegue) {
        let sourceViewController = sender.sourceViewController as! DatePickerTableViewController
        activity?.time = sourceViewController.date!
        let formatter = getDateFormatter()
        dateTableCell.detailTextLabel?.text = formatter.stringFromDate(activity!.time)
    }
    
    @IBAction func unwindOneToMany(sender: UIStoryboardSegue) {
        let source = sender.sourceViewController as! OneToManyTableViewController
        source.cell?.updateValues()
    }
    
    @IBAction func unwindCustomForm(sender: UIStoryboardSegue) {
//        let source = sender.sourceViewController as! OneToManyTableViewController
//        source.cell?.updateValues()
        self.vesselTableViewCell.updateValues()
        self.observersTableViewCell.updateValues()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 1 && (self.isNew || self.allowEditing) {
            let storyboard = UIStoryboard(name: "DatePicker", bundle: nil)
            let controller:DatePickerTableViewController = storyboard.instantiateInitialViewController() as! DatePickerTableViewController
            self.navigationController?.pushViewController(controller, animated: true)
            controller.date = activity!.time
        } else if indexPath.section == 0 && indexPath.row == 3 {
            let storyboard = UIStoryboard(name: "PhotoList", bundle: nil)
            let controller = storyboard.instantiateInitialViewController() as! PhotosCollectionViewController
            controller.activity = self.activity
            controller.editing = self.allowEditing
            self.navigationController?.pushViewController(controller, animated: true)
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == "Add any relevant comments here..." {
            textView.text = ""
            textView.textColor = UIColor.blackColor()
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            textView.text = "Add any relevant comments here..."
            textView.textColor = UIColor.lightGrayColor()
            self.activity?.remarks = ""
        } else {
            self.activity?.remarks = textView.text
        }
        textView.resignFirstResponder()
    }

    @IBAction func tapRecognizer(sender:AnyObject) {
        self.hideNotesKeyboard()
    }
    
    func hideNotesKeyboard() {
        self.remarksTextView.endEditing(true)
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
//
//        controller.takePhoto(sender)
    }
    
    override func viewWillAppear(animated: Bool) {
        if let model = self.activity {
            self.photosCell.detailTextLabel?.text = "\(model.photos.count)"
        } else {
            self.photosCell.detailTextLabel?.text = "0"
        }
    }
    
    
    
}
