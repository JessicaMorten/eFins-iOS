//
//  ActivityFormTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/8/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class ActivityFormTableViewController: UITableViewController, LocationManagerDelegate {

    // location field
    @IBOutlet weak var locationTableCell: UITableViewCell!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationViewingLabel: UILabel!
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
    @IBOutlet weak var locationDisplay: UITextField!

    
    @IBOutlet weak var saveButton: UIButton!
    
    var activity:Activity!
    var patrolLog:PatrolLog?

    // should be set by subclasses
    var activityType:String!
    var relationTableViewCells = [RelationTableViewCell]()
    var textViews = [UITextView]()
    var textFields = [UITextField]()
    
    var isNew = true
    var allowEditing = true
    var inWriteTransaction = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationLabel.text = " "
        self.locationViewingLabel.text = " "
        
        if self.activityType == nil {
            NSException.raise("ActivityFormMisconfigured", format: "ActivityForm activityType var is not set", arguments: getVaList([]))
        }
        
        if self.activity == nil {
            let realm = RLMRealm.defaultRealm()
            activity = Activity()
            activity.beginWriteTransaction()
            activity.type = activityType
            self.isNew = true
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel,
                target: self, action: "cancel")
            self.locationTableCell.textLabel?.text = "Include Location"
            activity.time = NSDate()
            if let user = (UIApplication.sharedApplication().delegate as! AppDelegate).getUser() {
                activity.users.addObject(user)
            }
            if let log = self.patrolLog {
                activity.patrolLog = log
                // the scemas for activities vs patrols don't match exactly so it's not that useful to set this
                activity.users = log.crew
                activity.freeTextCrew = log.freeTextCrew
            }
            
            realm.addObject(self.activity)
            activity.commitWriteTransaction()
            self.locationSwitch.setOn(true, animated: false)
            self.toggleLocationRecording(true)
        } else {
            self.isNew = false
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Plain, target: self, action: "back")
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: "editButtonTapped")
            self.saveButton.hidden = true
            self.dateTableCell.accessoryType = UITableViewCellAccessoryType.None
            self.locationTableCell.textLabel?.text = "Location"
            self.locationSwitch.hidden = true
            self.remarksTextView?.editable = false
            if self.activity.latitude == -1.0 {
                self.locationTableCell.accessoryType = UITableViewCellAccessoryType.None
                self.locationViewingLabel.text = "None recorded"
            } else {
                let (latDeg, latMin) = CoordinateConverter.decimalDegrees2degreesMinutes(degrees: self.activity.latitude)
                let (longDeg, longMin) = CoordinateConverter.decimalDegrees2degreesMinutes(degrees: self.activity.longitude)
                let latText = String(format: "%3.0f\u{00b0} %.3f\u{2032}", latDeg, latMin)
                let longText = String(format: "%3.0f\u{00b0} %.3f\u{2032}", longDeg, longMin)
                self.locationViewingLabel.text = "\(latText), \(longText)"
            }
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
        println("updatedAt")
        println(activity.updatedAt)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        LocationManager.sharedInstance.stopPreheat()
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
        println("back \(self.allowEditing)")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func saveAction(sender: AnyObject) {
        // TODO: Validation (if any?)
        if (self.activity.latitude == -1.0 && self.locationSwitch.on == true) {
            alert("Waiting for GPS Lock", "Your location has not yet been obtained. Please wait or turn of the Include Location switch.", self)
        } else {
            let realm = RLMRealm.defaultRealm()
            activity.beginWriteTransaction()
            realm.addObject(self.activity)
            activity.commitWriteTransaction()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func locationSwitchValueChanged(sender: UISwitch) {
        toggleLocationRecording(sender.on)
    }
    
    func toggleLocationRecording(on:Bool) {
        if on {
            self.locationActivityIndicator.hidden = false
            self.locationActivityIndicator.startAnimating()
            LocationManager.sharedInstance.addLocationManagerDelegate(self, accuracy: 30, timeout: 30)
            LocationManager.sharedInstance.stopPreheat()
        } else {
            self.locationLabel.text = " "
            let realm = RLMRealm.defaultRealm()
            activity.beginWriteTransaction()
            self.activity.latitude = -1.0
            self.activity.longitude = -1.0
            activity.commitWriteTransaction()
            self.locationActivityIndicator.hidden = true
            LocationManager.sharedInstance.removeLocationManagerDelegate(self)
            self.locationSwitch.setOn(false, animated: false)
        }
    }
    
    @IBAction func numPersonsOnBoardEditingEnded(sender: AnyObject) {
        if let n = self.numPersonsOnBoardTextField!.text.toInt() {
            let realm = RLMRealm.defaultRealm()
            activity.beginWriteTransaction()
            self.activity.numPersonsOnBoard = n
            activity.commitWriteTransaction()
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
        activity.beginWriteTransaction()
        activity?.time = sourceViewController.date!
        activity.commitWriteTransaction()
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
        
        if let pCell = self.photosCell {
            if let photosIndex = tableView.indexPathForCell(pCell) {
                if indexPath.section == photosIndex.section && indexPath.row == photosIndex.row {
                    let storyboard = UIStoryboard(name: "PhotoList", bundle: nil)
                    let controller = storyboard.instantiateInitialViewController() as! PhotosCollectionViewController
                    controller.activity = self.activity
                    controller.editing = self.allowEditing
                    self.navigationController?.pushViewController(controller, animated: true)
                    return
                }
            }
        }
        
        if let dCell = self.dateTableCell {
            if let datePickerIndex = tableView.indexPathForCell(dCell) {
                if indexPath.section == datePickerIndex.section && indexPath.row == datePickerIndex.row {
                    if allowEditing {
                        let storyboard = UIStoryboard(name: "DatePicker", bundle: nil)
                        let controller:DatePickerTableViewController = storyboard.instantiateInitialViewController() as! DatePickerTableViewController
                        self.navigationController?.pushViewController(controller, animated: true)
                        controller.date = activity!.time
                        return
                    } else {
                        if let row = tableView.indexPathForSelectedRow() {
                            tableView.deselectRowAtIndexPath(row, animated: false)
                            return
                        }
                    }
                }
            }
        }
        
        if let lCell = self.locationTableCell {
            if let lCellIndex = tableView.indexPathForCell(lCell) {
                if indexPath.section == lCellIndex.section && indexPath.row == lCellIndex.row {
                    if lCell.accessoryType != .None {
                        if tilesExist() {
                            let storyboard = UIStoryboard(name: "LocationSetting", bundle: nil)
                            let controller = storyboard.instantiateInitialViewController() as! LocationSettingController
                            controller.location = CLLocationCoordinate2D(latitude: activity.latitude, longitude: activity.longitude)
                            controller.manuallyEntered = false
                            controller.canEdit = allowEditing
                            
                            navigationController?.pushViewController(controller, animated: true)
                            //                    controller.setupWithLocation(location, wasManuallyEntered: false, withEditingAbility: allowEditing)
                        } else {
                            alert("Map Data not available", "Download maps from the settings tab while connected to the internet for offline use.", self)
                        }
                    }
                    if let row = tableView.indexPathForSelectedRow() {
                        tableView.deselectRowAtIndexPath(row, animated: false)
                    }
                    return                    
                }
            }
        }

        
        if allowEditing == false {
            if let row = tableView.indexPathForSelectedRow() {
                tableView.deselectRowAtIndexPath(row, animated: false)
            }            
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
        activity.beginWriteTransaction()
        if textView.text == "" {
            textView.text = "Add any relevant comments here..."
            textView.textColor = UIColor.lightGrayColor()
            self.activity?.remarks = ""
        } else {
            self.activity?.remarks = textView.text
        }
        activity.commitWriteTransaction()
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
        updateTitle()
    }
    
    func updateTitle() {
        
        var title = ""
        switch self.activity.type {
        case Activity.Types.CDFW_COMM:
            title += "Commercial Boarding"
        case Activity.Types.CDFW_REC:
            title += "Recreational Contact"
        case Activity.Types.LOG:
            title += "Activity Log"
        case Activity.Types.NPS:
            title += "NPS Contact"
        default:
            title += ""
        }
        if let vessel = activity.patrolLog?.agencyVessel {
            title += " - \(vessel.name)"
        }
        let formatter = getShorthandDayFormatter()
        title += " \(formatter.stringFromDate(activity.time))"
        self.title = title
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
    
    
    // LocationManagerDelegate
    func locationManagerDidUpdateLocation(location: CLLocation) {
        activity.beginWriteTransaction()
        self.activity.latitude = location.coordinate.latitude
        self.activity.longitude = location.coordinate.longitude
        activity.commitWriteTransaction()
        LocationManager.sharedInstance.removeLocationManagerDelegate(self)
        locationActivityIndicator.stopAnimating()
        self.locationLabel.text = "\(self.activity.latitude), \(self.activity.longitude)"
        let topViewController = self.navigationController?.topViewController
        if topViewController != nil {
            if topViewController!.isKindOfClass(LocationSettingController) {
                (topViewController as! LocationSettingController).updateLocation(location.coordinate)
            }
        }
    }
    
    func locationManagerDidFailToObtainLocation() {
        println("We tried to get a location and couldn't.  Retry?")
        LocationManager.sharedInstance.removeLocationManagerDelegate(self)
        alert("Failed to set Location", "Could not acheive GPS lock. To try again, toggle the location switch.", self)
        self.toggleLocationRecording(false)
    }
    
    func beginWriteTransaction() {
        if self.inWriteTransaction {
            NSException.raise("Realm Transaction Error", format: "Tried to begin transaction, but one is open", arguments: getVaList([]))
        }
        self.inWriteTransaction = true
        RLMRealm.defaultRealm().beginWriteTransaction()
    }
    
    func commitWriteTransaction() {
        if self.inWriteTransaction {
            self.activity.updatedAt = NSDate()
            if !isNew {
                self.activity.dirty = true
            }
            RLMRealm.defaultRealm().commitWriteTransaction()
            self.inWriteTransaction = false
        } else {
            if self.inWriteTransaction {
                NSException.raise("Realm Transaction Error", format: "Tried to commit transaction, but none open", arguments: getVaList([]))
            }
        }
    }
    
}
