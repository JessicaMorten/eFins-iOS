//
//  PickerTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 4/2/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class PickerTableViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {

    var entryFieldName:String?
    var propertyName:String!
    var propertyClassName:String!
    var secondaryProperty:RLMProperty?
    var labelProperty:String?
    var filteredObjects = [RLMObject]()
    var selection:RLMObject?
    var alreadySelected:RLMArray?
    var secondaryAlreadySelected:RLMArray?
    var cell:RelationTableViewCell?
    var model:RLMObject?
    var modelFormId:String?
    var modelFormStoryboard:UIStoryboard?
    var skipSearch = false
    var reversed = false
    @IBOutlet weak var helpLabel: UILabel!
    var searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.searchController = UISearchController()
        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.definesPresentationContext = true
        self.searchController.searchBar.sizeToFit()

        // self.searchDisplayController?.searchResultsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "default")
        if entryFieldName != nil {
            self.searchController.searchBar.placeholder = "Tap here to search, show most used choices, or create new \(entryFieldName!.lowercaseString)"
        }
        
        if self.items().count < 1 {
            let label = UILabel()
            
//            self.tableView.tableFooterView = 
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.helpLabel.hidden = self.items().count != 0
        self.searchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchController.searchBar
//        self.tableView.reloadData()
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        self.filterContentForSearchText(self.searchController.searchBar.text)
        self.tableView.reloadData()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        for view in self.tableView.subviews {
            if view is UIButton {
                view.removeFromSuperview()
            }
        }
        dispatch_async(dispatch_get_main_queue()) {
            if self.filteredObjects.count < 1 && count(searchText) > 0 {
                let button = UIButton()
                // x, y, width, height
                button.frame = CGRectMake((self.view.frame.width / 2) - 200, 120, 400, 40)
                button.addTarget(self, action: "addNewObject", forControlEvents: UIControlEvents.TouchUpInside)
                button.layer.cornerRadius = 4.0
                button.backgroundColor = UIColor(hex: 0x112244, alpha: 1.0)
                if self.labelAlreadyInList(searchText, list1: self.alreadySelected, list2: self.secondaryAlreadySelected) {
                    button.enabled = false
                    button.setTitle("\"\(searchText)\" already selected", forState: UIControlState.Normal)
                    button.backgroundColor = UIColor(hex: 0x112244, alpha: 0.5)
                } else {
                    button.setTitle("Add \"\(searchText)\" to list", forState: UIControlState.Normal)
                }
    //            self.tableView.insertSubview(button, belowSubview: label)
                self.tableView.insertSubview(button, atIndex: 0)
            }
        }
    }
    
    func addNewObject() {
        let text = self.searchController.searchBar.text
        var Model = Models[propertyClassName]! as RLMObject.Type
        let controller = self.getCustomForm()
        if controller != nil {
            let 💩 = controller as! ItemForm
            💩.label = text
//            self.navigationItem.title = "Cancel"
            self.navigationController?.pushViewController(controller!, animated: true)
        } else {
            let object = Model()
            object.setValue(text, forKey: self.labelProperty!)
            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            realm.addObject(object)
            realm.commitWriteTransaction()
            self.selection = object
            if self.cell != nil {
                cell?.unwindOneToOnePicker(self)
                self.navigationController?.popViewControllerAnimated(true)
            } else {
                self.performSegueWithIdentifier("UnwindPicker", sender: self)
            }
        }
    }
    
    @IBAction func unwindCustomForm(sender: UIStoryboardSegue) {
        self.selection = (sender.sourceViewController as! ItemForm).model
        if self.cell != nil {
            self.navigationController?.popToRootViewControllerAnimated(true)
            cell?.unwindOneToOnePicker(self)
        }
    }

    
    func searchActive() -> Bool {
        return self.searchController.active
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if searchActive() {
            if count(self.searchController.searchBar.text) == 0 {
                if indexPath.row == 0 {
                    return
                } else {
                    self.selection = self.filteredObjects[indexPath.row - 1] as RLMObject
                }
            } else {
                self.selection = self.filteredObjects[indexPath.row] as RLMObject
            }
        } else {
            self.selection = items()[indexPath.row] as RLMObject
        }
        // means it's a one-to-one relation
        if cell != nil {
            cell?.unwindOneToOnePicker(self)
            self.navigationController?.popViewControllerAnimated(true)
        } else {
            // one-to-many
            self.performSegueWithIdentifier("UnwindPicker", sender: self)
        }
    }
    
//    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchScope searchOption: Int) -> Bool {
//        self.filterContentForSearchText(self.searchDisplayController!.searchBar.text)
//        return true
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func items() -> [RLMObject] {
        var items = [RLMObject]()
        let schema = RLMRealm.defaultRealm().schema
        var Model = Models[propertyClassName]! as RLMObject.Type
        var results = Model.allObjects()
        if results.count > 0 {
            for index in 0...(Int(results.count) - 1) {
                items.append(results.objectAtIndex(UInt(index)) as! RLMObject)
            }            
        }
        if secondaryProperty != nil {
            Model = Models[secondaryProperty!.objectClassName]! as RLMObject.Type
            results = Model.allObjects()
            if results.count > 0 {
                for index in 0...(Int(results.count) - 1) {
                    items.append(results.objectAtIndex(UInt(index)) as! RLMObject)
                }
            }
        }
        items.sort {
            return (($0 as RLMObject).valueForKey(self.labelProperty!) as! String) < (($1 as RLMObject).valueForKey(self.labelProperty!) as! String)
        }
        return items.filter {
            return !self.alreadyInList($0, list1: self.alreadySelected, list2: self.secondaryAlreadySelected)
        }
    }
    
    func alreadyInList(item:RLMObject, list1:RLMArray?, list2:RLMArray?) -> Bool {
        if list1 != nil && list1?.count > 0 {
            for index in 1...(list1!.count) {
                let object = list1!.objectAtIndex(index - 1) as! RLMObject
                if object.isEqualToObject(item) {
                    return true
                }
            }
        }
        if list2 != nil && list2?.count > 0 {
            for index in 1...(list2!.count) {
                let object = list2!.objectAtIndex(index - 1) as! RLMObject
                if object.isEqualToObject(item) {
                    return true
                }
            }
        }

        return false
    }

    func labelAlreadyInList(label:String, list1:RLMArray?, list2:RLMArray?) -> Bool {
        if list1 != nil && list1?.count > 0 {
            for index in 1...(list1!.count) {
                let object = list1!.objectAtIndex(index - 1) as! RLMObject
                let objectLabel = object.valueForKey(self.labelProperty!) as! String
                if objectLabel.lowercaseString == label.lowercaseString {
                    return true
                }
            }
        }
        if list2 != nil && list2?.count > 0 {
            for index in 1...(list2!.count) {
                let object = list2!.objectAtIndex(index - 1) as! RLMObject
                let objectLabel = object.valueForKey(self.labelProperty!) as! String
                if objectLabel.lowercaseString == label.lowercaseString {
                    return true
                }
            }
        }
        
        return false
    }

    
    func filterContentForSearchText(searchText: String) {
        
        var Model = Models[propertyClassName]! as RLMObject.Type
        // That dumb fucking CONTAINS[c] means case insensitive - CB
        if count(searchText) == 0 {
            self.filteredObjects = RecentValues.getRecent(self.model!, propertyClassName: self.propertyClassName, propertyName: self.propertyName, secondaryProperty: secondaryProperty).filter {
                return !self.alreadyInList($0, list1: self.alreadySelected, list2: self.alreadySelected)
            }
        } else {
            let predicate = NSPredicate(format: "\(labelProperty!) CONTAINS[c] %@", searchText)
            self.filteredObjects = self.items().filter {
                return ($0.valueForKey(self.labelProperty!) as! String).lowercaseString.rangeOfString(
                    searchText.lowercaseString) != nil
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if searchActive() {
            if count(self.searchController.searchBar.text) == 0 {
                if self.filteredObjects.count > 0 {
                    return self.filteredObjects.count + 1
                } else {
                    return 0
                }
            } else {
                return self.filteredObjects.count
            }
        } else {
            return Int(items().count)
        }
    }
    
    func getCustomForm() -> UITableViewController? {
        if self.modelFormStoryboard != nil {
            return self.modelFormStoryboard?.instantiateViewControllerWithIdentifier(self.modelFormId!) as? UITableViewController
        } else {
            return nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var object:RLMObject
        if searchActive() {
            if count(self.searchController.searchBar.text) == 0 {
                if self.filteredObjects.count > 0 && indexPath.row == 0 {
                    let cell = tableView.dequeueReusableCellWithIdentifier("recent", forIndexPath: indexPath) as! UITableViewCell
                    return cell
                } else {
                    object = self.filteredObjects[indexPath.row - 1] as RLMObject
                }
            } else {
                object = self.filteredObjects[indexPath.row] as RLMObject
            }
        } else {
            object = items()[indexPath.row] as RLMObject
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("default", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = object.valueForKey(labelProperty!) as? String
        
        // Configure the cell...

        return cell
    }
    
}
