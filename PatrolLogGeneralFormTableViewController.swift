//
//  PatrolLogGeneralFormTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/12/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class PatrolLogGeneralFormTableViewController: UITableViewController, UITextFieldDelegate {

    var patrolLog:PatrolLog!
    var textFields = [UITextField]()
    var relationTableViewCells = [RelationTableViewCell]()
    var allowEditing = true
    
    @IBOutlet weak var portHoursBroughtForwardCell: UITableViewCell!
    @IBOutlet weak var portHoursBroughtForwardField: UITextField!
    @IBOutlet weak var starboardHoursBroughtForwardCell: UITableViewCell!
    @IBOutlet weak var starboardHoursBroughtForwardField: UITextField!
    @IBOutlet weak var portHoursLogged: UITableViewCell!
    @IBOutlet weak var portHoursLoggedField: UITextField!
    @IBOutlet weak var starboardHoursLogged: UITableViewCell!
    @IBOutlet weak var starboardHoursLoggedField: UITextField!
    @IBOutlet weak var fuelToDate: UITableViewCell!
    @IBOutlet weak var fuelToDateField: UITextField!
    @IBOutlet weak var fuelPurchased: UITableViewCell!
    @IBOutlet weak var fuelPurchasedField: UITextField!
    @IBOutlet weak var generatorHoursBroughtForward: UITableViewCell!
    @IBOutlet weak var generatorHoursBroughtForwardField: UITextField!
    @IBOutlet weak var generatorHoursLogged: UITableViewCell!
    @IBOutlet weak var generatorHoursLoggedField: UITextField!
    @IBOutlet weak var outboardHoursBroughtForward: UITableViewCell!
    @IBOutlet weak var outboardHoursBroughtForwardField: UITextField!
    @IBOutlet weak var outboardHoursLogged: UITableViewCell!
    @IBOutlet weak var outboardHoursLoggedField: UITextField!
    @IBOutlet weak var dateTableCell: UITableViewCell!
    @IBOutlet weak var vesselCell: RelationTableViewCell!
    @IBOutlet weak var portCell: RelationTableViewCell!
    @IBOutlet weak var crewCell: RelationTableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textFields.append(self.portHoursBroughtForwardField)
        textFields.append(self.starboardHoursBroughtForwardField)
        textFields.append(self.portHoursLoggedField)
        textFields.append(self.starboardHoursLoggedField)
        textFields.append(self.fuelToDateField)
        textFields.append(self.fuelPurchasedField)
        textFields.append(self.generatorHoursBroughtForwardField)
        textFields.append(self.generatorHoursLoggedField)
        textFields.append(self.outboardHoursBroughtForwardField)
        textFields.append(self.outboardHoursLoggedField)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        
        self.portHoursBroughtForwardCell.textLabel?.text = "Port Hours Brought Forward"
        self.starboardHoursBroughtForwardCell.textLabel?.text = "Starboard Hours Brought Forward"
        self.portHoursLogged.textLabel?.text = "Port Hours Logged"
        self.starboardHoursLogged.textLabel?.text = "Starboard Hours Logged"
        self.fuelToDate.textLabel?.text = "Fuel to Date"
        self.fuelPurchased.textLabel?.text = "Fuel Purchased"
        self.generatorHoursBroughtForward.textLabel?.text = "Generator Hours Brought Forward"
        self.generatorHoursLogged.textLabel?.text = "Generator Hours Logged"
        self.outboardHoursBroughtForward.textLabel?.text = "Outboard Hours Brought Forward"
        self.outboardHoursLogged.textLabel?.text = "Outboard Hours Logged"
        
        var i = 100
        for field in self.textFields {
            field.tag = i
            i++
            field.keyboardType = UIKeyboardType.NumberPad
            field.enabled = self.allowEditing
            field.delegate = self
        }
        
        self.vesselCell.setup(patrolLog, allowEditing: allowEditing, property: "agencyVessel", secondaryProperty: nil)
        self.portCell.setup(patrolLog, allowEditing: allowEditing, property: "departurePort", secondaryProperty: nil)
        self.crewCell.setup(patrolLog, allowEditing: allowEditing, property: "crew", secondaryProperty: "freeTextCrew")
        self.relationTableViewCells.append(self.vesselCell)
        self.relationTableViewCells.append(self.portCell)
        self.relationTableViewCells.append(self.crewCell)
        showWeather()
        showEngineHoursAndFuel()
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        var value = 0
        if let val = textField.text.toInt() {
            value = val
        }
        switch textField {
        case self.portHoursBroughtForwardField:
            self.patrolLog.portHoursBroughtForward = Double(value)
        case self.starboardHoursBroughtForwardField:
            self.patrolLog.starboardHoursBroughtForward = Float(value)
        case self.portHoursLogged:
            self.patrolLog.portHoursBroughtForward = Double(value)
        case self.starboardHoursLoggedField:
            self.patrolLog.starboardLoggedHours = Float(value)
        case self.fuelToDateField:
            self.patrolLog.fuelToDate = Float(value)
        case self.fuelPurchasedField:
            self.patrolLog.fuelPurchased = Float(value)
        case self.generatorHoursBroughtForwardField:
            self.patrolLog.generatorHoursBroughtForward = Float(value)
        case self.generatorHoursLoggedField:
            self.patrolLog.generatorLoggedHours = Float(value)
        case self.outboardHoursBroughtForwardField:
            self.patrolLog.outboardHoursBroughtForward = Float(value)
        case self.outboardHoursLoggedField:
            self.patrolLog.outboardLoggedHours = Float(value)
        default:
            println("unrecognized field")
        }
        realm.commitWriteTransaction()
        showEngineHoursAndFuel()
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if textField.text == "0.0" || textField.text == "0" {
            textField.text = ""
        }
    }

//    Doesn't work. iOS is stupid
//    func textFieldShouldReturn(textField: UITextField) -> Bool {
//        view = self.view.viewWithTag(textField.tag + 1)
//        println(view)
//        if view != nil {
//            textField.resignFirstResponder()
//        } else {
//            view.becomeFirstResponder()
//        }
//        return true
//    }
    
    func showEngineHoursAndFuel() {
        self.portHoursBroughtForwardField.text = "\(patrolLog.portHoursBroughtForward)"
        self.starboardHoursBroughtForwardField.text = "\(patrolLog.starboardHoursBroughtForward)"
        self.portHoursLoggedField.text = "\(patrolLog.portLoggedHours)"
        self.starboardHoursLoggedField.text = "\(patrolLog.starboardLoggedHours)"
        self.fuelToDateField.text = "\(patrolLog.fuelToDate)"
        self.fuelPurchasedField.text = "\(patrolLog.fuelPurchased)"
        self.generatorHoursBroughtForwardField.text = "\(patrolLog.generatorHoursBroughtForward)"
        self.generatorHoursLoggedField.text = "\(patrolLog.generatorLoggedHours)"
        self.outboardHoursBroughtForwardField.text = "\(patrolLog.outboardHoursBroughtForward)"
        self.outboardHoursLoggedField.text = "\(patrolLog.outboardLoggedHours)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func startEditing() {
        
    }
    
    @IBAction func unwindDatePicker(sender: UIStoryboardSegue) {
        let sourceViewController = sender.sourceViewController as! DatePickerTableViewController
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        patrolLog.date = sourceViewController.date!
        realm.commitWriteTransaction()
        let formatter = getDateFormatter()
        dateTableCell.detailTextLabel?.text = formatter.stringFromDate(patrolLog.date)
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
        let datePickerIndex = tableView.indexPathForCell(self.dateTableCell)
        if datePickerIndex != nil && indexPath.section == datePickerIndex?.section && indexPath.row == datePickerIndex?.row {
            let storyboard = UIStoryboard(name: "DatePicker", bundle: nil)
            let controller:DatePickerTableViewController = storyboard.instantiateInitialViewController() as! DatePickerTableViewController
            self.navigationController?.pushViewController(controller, animated: true)
            controller.date = patrolLog.date
        } else if indexPath.section == 2 {
            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()

            if let cell = tableView.cellForRowAtIndexPath(indexPath) {
                var on:Bool
                if cell.accessoryType == UITableViewCellAccessoryType.Checkmark {
                    cell.accessoryType = UITableViewCellAccessoryType.None
                    on = false
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.Checkmark
                    on = true
                }
                switch cell.textLabel!.text! {
                    case "Clear":
                        patrolLog.wasClear = on
                    case "Wind":
                        patrolLog.wasWindy = on
                    case "Fog":
                        patrolLog.wasFoggy = on
                    case "Calm":
                        patrolLog.wasCalm = on
                    case "Rain":
                        patrolLog.wasRainy = on
                    case "Small Craft Advisory":
                        patrolLog.hadSmallCraftAdvisory = on
                    case "Gale":
                        patrolLog.hadGale = on
                    default:
                        println("Should not get here")
                }
            }
            realm.commitWriteTransaction()
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }

    func showWeather() {
        let rows = tableView.numberOfRowsInSection(0)
        var i = 0
        while i < rows {
            let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 2))
            var type = UITableViewCellAccessoryType.None
            var val = false
            if let text = cell?.textLabel?.text {
                switch text {
                case "Clear":
                    val = patrolLog.wasClear
                case "Wind":
                    val = patrolLog.wasWindy
                case "Fog":
                    val = patrolLog.wasFoggy
                case "Calm":
                    val = patrolLog.wasCalm
                case "Rain":
                    val = patrolLog.wasRainy
                case "Small Craft Advisory":
                    val = patrolLog.hadSmallCraftAdvisory
                case "Gale":
                    val = patrolLog.hadGale
                default:
                    println("Should not get here")
                }
                if val == true {
                    type = UITableViewCellAccessoryType.Checkmark
                }
            }
            cell?.accessoryType = type
            i++
        }
    }
    
    @IBAction func tapRecognizer(sender:AnyObject) {
        println("tap")
        stopAllEditing()
    }
    
    func stopAllEditing() {
        for field in self.textFields {
            field.endEditing(true)
        }
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if cell is RelationTableViewCell {
            (cell as! RelationTableViewCell).displayDetails(self)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
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

    
    // MARK: - Table view data source


    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
