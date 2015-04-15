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
    var property:RLMProperty?
    var secondaryProperty:RLMProperty?
    var labelProperty:String?
    var filteredObjects = [RLMObject]()
    var selection:RLMObject?
    var alreadySelected:RLMArray?
    var secondaryAlreadySelected:RLMArray?
    var model:RLMObject?
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
            if self.filteredObjects.count < 1 && count(searchText) > 2 {
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

//    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
//        self.filterContentForSearchText(searchString)
//        dispatch_async(dispatch_get_main_queue()) {
//            for view in self.searchDisplayController!.searchResultsTableView.subviews {
//                if view is UILabel && self.filteredObjects.count < 1 {
//                    let label = view as! UILabel
//                    label.text = "No search results"
//                    let button = UIButton()
//                    // x, y, width, height
//                    button.frame = CGRectMake((self.view.frame.width / 2) - 200, label.frame.minY + 45, 400, 40)
//                    button.addTarget(self, action: "addNewObject", forControlEvents: UIControlEvents.TouchUpInside)
//                    button.layer.cornerRadius = 4.0
//                    button.backgroundColor = UIColor(hex: 0x112244, alpha: 1.0)
//                    if self.labelAlreadyInList(searchString, list1: self.alreadySelected, list2: self.secondaryAlreadySelected) {
//                        button.enabled = false
//                        button.setTitle("\"\(searchString)\" already selected", forState: UIControlState.Normal)
//                        button.backgroundColor = UIColor(hex: 0x112244, alpha: 0.5)
//                    } else {
//                        button.setTitle("Add \"\(searchString)\" to list", forState: UIControlState.Normal)
//                    }
//                    self.searchDisplayController!.searchResultsTableView.insertSubview(button, belowSubview: label)
//                    break
//                } else if view is UIButton {
//                    view.removeFromSuperview()
//                }
//            }
//        }
//        return true
//    }
    
    func addNewObject() {
        let text = self.searchController.searchBar.text
        var Model = Models[property!.objectClassName]! as RLMObject.Type
        let object = Model()
        object.setValue(text, forKey: self.labelProperty!)
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        realm.addObject(object)
        realm.commitWriteTransaction()
        self.selection = object
        self.performSegueWithIdentifier("UnwindPicker", sender: self)
    }
    
    func searchActive() -> Bool {
        return self.searchController.active
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if searchActive() {
            self.selection = self.filteredObjects[indexPath.row] as RLMObject
        } else {
            self.selection = items()[indexPath.row] as RLMObject
        }
        self.performSegueWithIdentifier("UnwindPicker", sender: self)
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
        var Model = Models[property!.objectClassName]! as RLMObject.Type
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
        return items.filter {
            return !self.alreadyInList($0, list1: self.alreadySelected, list2: self.alreadySelected)
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
        
        var Model = Models[property!.objectClassName]! as RLMObject.Type
        // That dumb fucking CONTAINS[c] means case insensitive - CB
        if count(searchText) == 0 {
            println("use recently used items")
            self.filteredObjects = RecentValues.getRecent(self.model!, property: self.property!)
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
            if self.filteredObjects.count > 0 {
                return self.filteredObjects.count
            } else {
                return 0
            }
        } else {
            return Int(items().count)
        }
    }


    
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var object:RLMObject
        if searchActive() {
            object = self.filteredObjects[indexPath.row] as RLMObject
        } else {
            object = items()[indexPath.row] as RLMObject
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("default", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = object.valueForKey(labelProperty!) as! String
        
        // Configure the cell...

        return cell
    }
    

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
