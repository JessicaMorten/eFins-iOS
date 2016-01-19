//
//  OneToManyTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 4/1/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class OneToManyTableViewController: UITableViewController {

    var entryFieldName:String?
    var model:RLMObject?
    var propertyName: String!
    var propertyClassName: String!
    var secondaryProperty: RLMProperty?
    var modelLabelProperty: String = "name"
    var modelFormId: String?
    var modelFormStoryboard: UIStoryboard?
    var allowEditing = true
    var skipSearch = false
    var reversed = false
    weak var cell:RelationTableViewCell?
    @IBOutlet weak var addHelpLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if allowEditing {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "add")
        }
        let attr = addHelpLabel.attributedText!.mutableCopy() as! NSMutableAttributedString
        attr.mutableString.replaceOccurrencesOfString("<items>", withString: entryFieldName!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: NSMakeRange(0, attr.mutableString.length))
        addHelpLabel.attributedText = attr
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.addHelpLabel.hidden = self.items().count != 0
    }

    // MARK: - Table view data source
    
    func items() -> NSArray {
        var results:[RLMObject]
        results = rlmArrayToNSArray(model!.valueForKey(propertyName) as! RLMArray)
        if secondaryProperty != nil {
            results = results + rlmArrayToNSArray(model!.valueForKey(secondaryProperty!.name) as! RLMArray)
        }
        return results
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return Int(items().count)
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("default", forIndexPath: indexPath) 
        let item:RLMObject = self.items().objectAtIndex(indexPath.row) as! RLMObject
        cell.textLabel?.text = item.valueForKey(modelLabelProperty) as! String
        if self.propertyClassName == item.objectSchema.className && self.modelFormStoryboard != nil {
            cell.accessoryType = UITableViewCellAccessoryType.DetailButton
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.None
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let item:RLMObject = self.items().objectAtIndex(indexPath.row) as! RLMObject
        if self.propertyClassName == item.objectSchema.className {
            displayDetails(item)
        } else {
            print("this shouldn't happen")
        }
    }
    
    func displayDetails(item:RLMObject) {
        if self.modelFormStoryboard != nil {
            let form = self.modelFormStoryboard!.instantiateViewControllerWithIdentifier(self.modelFormId!) 
            (form as! ItemForm).label = self.cell?.textLabel?.text
            (form as! ItemForm).model = item
            (form as! ItemForm).allowEditing = false
            self.navigationController?.pushViewController(form, animated: true)
        }
    }
    

    @IBAction func unwindPicker(sender: UIStoryboardSegue) {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        var selection:RLMObject
        if sender.sourceViewController is PickerTableViewController {
            let sourceViewController = sender.sourceViewController as! PickerTableViewController
            selection = sourceViewController.selection!
        } else {
            let sourceViewController = sender.sourceViewController as! ItemForm
            selection = sourceViewController.model!
        }
        // Determine appropriate property (primary or secondary property)
        var prop:RLMArray
        if propertyClassName == selection.objectSchema.className {
            let getter = propertyName
            prop = model?.valueForKey(getter) as! RLMArray
        } else {
            let getter = secondaryProperty!.name!
            prop = model?.valueForKey(getter) as! RLMArray
        }
        if self.allowEditing {
            // append to array
            let index = prop.indexOfObject(selection)
            if index == UInt(NSNotFound) {
                prop.addObject(selection)
            }
            // save Model
            // reload table data
        } else {
            print("Not allowing editing")
        }
        if let m = self.model as? EfinsModel {
            m.dirty = true
        }
        realm.commitWriteTransaction()
        self.tableView.reloadData()
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    func removeItem(item:RLMObject) {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        let primaryItems = model!.valueForKey(propertyName) as! RLMArray
        if primaryItems.count > 0 {
            for i in 1...(primaryItems.count) {
                if (primaryItems.objectAtIndex(UInt(i - 1)) as! RLMObject).isEqualToObject(item) {
                    primaryItems.removeObjectAtIndex(UInt(i-1))
                    if let m = self.model as? EfinsModel {
                        m.dirty = true
                    }
                    realm.commitWriteTransaction()
                    return
                }
            }
        }
        
        if self.secondaryProperty != nil {
            let secondaryItems = model!.valueForKey(secondaryProperty!.name) as! RLMArray
            if secondaryItems.count > 0 {
                for i in 1...(secondaryItems.count) {
                    if (secondaryItems.objectAtIndex(UInt(i - 1)) as! RLMObject).isEqualToObject(item) {
                        secondaryItems.removeObjectAtIndex(UInt(i-1))
                        if let m = self.model as? EfinsModel {
                            m.dirty = true
                        }
                        realm.commitWriteTransaction()
                        return
                    }
                }
            }
        }
    }
    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            let item = self.items().objectAtIndex(indexPath.row) as! RLMObject
            let name = item.valueForKey("name") as! String
            self.removeItem(item)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return allowEditing
    }


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

    // MARK: - Navigation

    func add() {
        if skipSearch {
            var Model = Models[propertyClassName]! as RLMObject.Type
            if let controller = self.getCustomForm() {
//                self.navigationItem.title = "Cancel"
                self.navigationController?.pushViewController(controller, animated: true)
            }
        } else {
            self.performSegueWithIdentifier("Pick", sender: self)
        }
    }
    
    func getCustomForm() -> UITableViewController? {
        if self.modelFormStoryboard != nil {
            return self.modelFormStoryboard?.instantiateViewControllerWithIdentifier(self.modelFormId!) as? UITableViewController
        } else {
            return nil
        }
    }
    
    @IBAction func unwindCustomFormNoSearch(sender: UIStoryboardSegue) {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        let selection = (sender.sourceViewController as! ItemForm).model!
        if reversed {
            selection.setValue(self.model, forKeyPath: "activity")
            if let eFinsModel = selection as? EfinsModel {
                eFinsModel.dirty = true
                eFinsModel.updatedAt = NSDate()
            }
        } else {
            var prop:RLMArray
            if propertyClassName == selection.objectSchema.className {
                let getter = propertyName
                prop = model?.valueForKey(getter) as! RLMArray
            } else {
                let getter = secondaryProperty!.name!
                prop = model?.valueForKey(getter) as! RLMArray
            }
            if self.allowEditing {
                // append to array
                let index = prop.indexOfObject(selection)
                if index == UInt(NSNotFound) {
                    prop.addObject(selection)
                }
                // save Model
                // reload table data
            } else {
                print("Not allowing editing")
            }
        }
        if let m = self.model as? EfinsModel {
            m.dirty = true
        }
        realm.commitWriteTransaction()
        self.tableView.reloadData()
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Pick" {
            // Get the new view controller using [segue destinationViewController].
            // Pass the selected object to the new view controller.
            let controller = segue.destinationViewController as! PickerTableViewController
            controller.propertyName = self.propertyName
            controller.propertyClassName = self.propertyClassName
            controller.secondaryProperty = self.secondaryProperty
            controller.labelProperty = self.modelLabelProperty
            controller.entryFieldName = self.entryFieldName
            controller.model = self.model
            controller.modelFormId = self.modelFormId
            controller.modelFormStoryboard = self.modelFormStoryboard
            controller.reversed = reversed
            let getter = propertyName
            controller.alreadySelected = model?.valueForKey(getter) as? RLMArray
            if secondaryProperty != nil {
                let secgetter = secondaryProperty!.name!
                controller.secondaryAlreadySelected = model?.valueForKey(secgetter) as? RLMArray                
            }
        }
    }

}
