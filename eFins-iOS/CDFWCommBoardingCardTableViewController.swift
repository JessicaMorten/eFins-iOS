//
//  CDFWCommBoardingCardTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/1/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class CDFWCommBoardingCardTableViewController: UITableViewController, UITextViewDelegate {
    
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
    @IBOutlet weak var captainCell: RelationTableViewCell!
    @IBOutlet weak var activityCell: RelationTableViewCell!
    @IBOutlet weak var catchesCell: RelationTableViewCell!
    @IBOutlet weak var citationsCell: RelationTableViewCell!
    @IBOutlet weak var categoryOfBoardingCell: UITableViewCell!
    
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
            realm.beginWriteTransaction()
            activity = Activity()
            // TODO: Make an actual type
            activity?.type = Activity.Types.CDFW_COMM
            //            let predicate = NSPredicate(format: "color = %@ AND name BEGINSWITH %@", "tan", "B")
            //            let type = ContactType.objectsWithPredicate(predicate).firstObject()
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel,
                target: self, action: "cancel")
            self.locationTableCell.textLabel?.text = "Include Location"
            activity?.time = NSDate()
            let formatter = getDateFormatter()
            dateTableCell.detailTextLabel?.text = formatter.stringFromDate(activity!.time)
            realm.addObject(self.activity)
            realm.commitWriteTransaction()
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
            self.remarksTextView.editable = false
            self.categoryOfBoardingCell.accessoryType = UITableViewCellAccessoryType.None
        }
        self.observersTableViewCell.setup(self.activity!, allowEditing: allowEditing, property: "freeTextCrew", secondaryProperty: "users")
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
    }
    
    // MARK: Actions
    
    func cancel() {
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
//        override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//            // Get the new view controller using [segue destinationViewController].
//            // Pass the selected object to the new view controller.
//            let controller = segue.destinationViewController
//            if controller is BoardingTypeTableViewController && self.isNew {
//                
//            }
//        }
//    
    
    override func shouldPerformSegueWithIdentifier(identifier: String?, sender: AnyObject?) -> Bool {
        if self.isNew == false {
            if sender is UITableViewCell && (sender as! UITableViewCell) == self.categoryOfBoardingCell {
                return false
            }
        }
        return true
    }
    
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
        } else if indexPath.section == 5 && indexPath.row == 0 {
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
    
    @IBAction func unwindBoardingType(sender:UIStoryboardSegue) {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        self.activity!.categoryOfBoarding = (sender.sourceViewController as! BoardingTypeTableViewController).selection
        realm.commitWriteTransaction()
        self.categoryOfBoardingCell.detailTextLabel?.text = activity!.categoryOfBoarding
    }
    
    
    
}
