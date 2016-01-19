//
//  LogbookTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/25/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class LogbookTableViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {

    var token:RLMNotificationToken?
    var searchController = UISearchController(searchResultsController: nil)
    var filteredObjects = [RLMObject]()

    var _activities: RLMResults {
        get {
            //return Activity.allObjects().sortedResultsUsingProperty("time", ascending: false)
            return Activity.objectsWhere("deletedAt == %@", NSDate(timeIntervalSince1970:0)).sortedResultsUsingProperty("time", ascending: false)
        }
    }
    
    var items: [RLMObject] {
        get {
            var items: Array = [RLMObject]()
            var i = 0
            var activities = _activities
            while UInt(i) < activities.count {
                items.append(activities[UInt(i)] as! RLMObject)
                i++
            }
            var patrolLogs = PatrolLog.objectsWhere("deletedAt == %@", NSDate(timeIntervalSince1970:0)).sortedResultsUsingProperty("date", ascending: false)
            i = 0
            while UInt(i) < patrolLogs.count {
                items.append(patrolLogs[UInt(i)] as! RLMObject)
                i++
            }
            items.sort {
                var date1:NSDate
                var date2:NSDate
                if $0 is Activity {
                    date1 = ($0 as! Activity).time
                } else {
                    date1 = ($0 as! PatrolLog).date
                }
                if $1 is Activity {
                    date2 = ($1 as! Activity).time
                } else {
                    date2 = ($1 as! PatrolLog).date
                }
                return date1.compare(date2) == NSComparisonResult.OrderedDescending
            }
            return items
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.token = RLMRealm.defaultRealm().addNotificationBlock { note, realm in
                self.tableView.reloadData()
        }

        self.searchController.searchResultsUpdater = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.definesPresentationContext = true
        self.searchController.searchBar.sizeToFit()
        
        
        // self.searchDisplayController?.searchResultsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "default")
        self.searchController.searchBar.placeholder = "Search by vessel name & registration, or for people"
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        self.filterContentForSearchText(self.searchController.searchBar.text!)
        self.tableView.reloadData()
    }
    
    func filterContentForSearchText(text:String) {
        self.filteredObjects = self.items.filter { (item) -> Bool in
            if let patrolLog = item as? PatrolLog {
                return self.patrolMatches(patrolLog, text: text)
            } else if let activity = item as? Activity {
                if let patrolLog = activity.patrolLog {
                    if self.patrolMatches(patrolLog, text: text) {
                        return true
                    }
                }
                return self.activityMatches(activity, text: text);
            } else {
                return false
            }
        }
    }
    
    func patrolMatches(patrolLog:PatrolLog, text:String) -> Bool {
        // see if patrol.user name matches
        if patrolLog.user?.name.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil {
            return true
        }
        // look for crew member matches
        if let crew = patrolLog.freeTextCrew {
            if crew.count > 0 {
                var i = 0
                while UInt(i) < crew.count {
                    if let member = crew.objectAtIndex(UInt(i)) as? AgencyFreetextCrew {
                        if member.name.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil {
                            return true
                        }
                    }
                    i++
                }
            }
        }
        // look for agency vessel matches
        if let vessel = patrolLog.agencyVessel {
            if vessel.name.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil {
                return true
            }
        }
        return false
    }
    
    func activityMatches(activity:Activity, text:String) -> Bool {
        // check vessel name, fgNumber, & registration
        if let vessel = activity.vessel {
            if vessel.name.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil {
                return true
            }
            if vessel.registration.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil {
                return true
            }
            if vessel.fgNumber.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil {
                return true
            }
        }
        // check captain name
        if let captain = activity.captain {
            if captain.name.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil {
                return true
            }
        }
        // check crew names
        if let crew = activity.crew {
            if crew.count > 0 {
                var i = 0
                while UInt(i) < crew.count {
                    if let member = crew.objectAtIndex(UInt(i)) as? Person {
                        if member.name.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil {
                            return true
                        }
                    }
                    i++
                }
            }
        }
        // check person
        if let person = activity.person {
            if person.name.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil {
                return true
            }
        }
        
        // check users
        if let users = activity.users {
            if users.count > 0 {
                var i = 0
                while UInt(i) < users.count {
                    if let user = users.objectAtIndex(UInt(i)) as? User {
                        if user.name.rangeOfString(text, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil) != nil {
                            return true
                        }
                    }
                    i++
                }
            }
        }
        return false
    }
    
//    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
//        println("text did change")
//        self.tableView.reloadData()
////        for view in self.tableView.subviews {
////            if view is UIButton {
////                view.removeFromSuperview()
////            }
////        }
////        dispatch_async(dispatch_get_main_queue()) {
////            if self.filteredObjects.count < 1 && count(searchText) > 0 {
////                let button = UIButton()
////                // x, y, width, height
////                button.frame = CGRectMake((self.view.frame.width / 2) - 200, 120, 400, 40)
////                button.addTarget(self, action: "addNewObject", forControlEvents: UIControlEvents.TouchUpInside)
////                button.layer.cornerRadius = 4.0
////                button.backgroundColor = UIColor(hex: 0x112244, alpha: 1.0)
////                if self.labelAlreadyInList(searchText, list1: self.alreadySelected, list2: self.secondaryAlreadySelected) {
////                    button.enabled = false
////                    button.setTitle("\"\(searchText)\" already selected", forState: UIControlState.Normal)
////                    button.backgroundColor = UIColor(hex: 0x112244, alpha: 0.5)
////                } else {
////                    button.setTitle("Add \"\(searchText)\" to list", forState: UIControlState.Normal)
////                }
////                //            self.tableView.insertSubview(button, belowSubview: label)
////                self.tableView.insertSubview(button, atIndex: 0)
////            }
////        }
//    }

    
    override func viewWillAppear(animated: Bool) {
        self.tableView.reloadData()
        if let tb = self.tabBarController as? EFinsTabBarController {
            print(tb)
            if !tb.isDisplayingEditablePatrol() {
                DataSync.manager.enableSync()
            }
        }
        self.searchController.searchBar.sizeToFit()
        self.tableView.tableHeaderView = self.searchController.searchBar
    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchController.active {
            return self.filteredObjects.count
        } else {
            return self.items.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 
        let index = indexPath.row
        var model:RLMObject
        if self.searchController.active {
            model = self.filteredObjects[index]
        } else {
            model = items[index]
        }
        let formatter = getDateFormatter()
        var label = ""
        if let activity = model as? Activity {
            if let vessel = activity.patrolLog?.agencyVessel {
                label += vessel.name + " "
            }
            switch activity.type {
            case Activity.Types.LOG:
                label += "Activity Log"
            case Activity.Types.CDFW_REC:
                label += "Recreational Contact"
            case Activity.Types.CDFW_COMM:
                label += "Commercial Boarding"
            case Activity.Types.NPS:
                label += "NPS Contact Record"
            default:
                label += "Other"
            }
            
            if let observedVessel = activity.vessel {
                if !observedVessel.name.isEmpty {
                    label += " (\(observedVessel.name))"
                } else if !observedVessel.registration.isEmpty {
                    label += " (\(observedVessel.registration))"
                }
            }
            cell.detailTextLabel?.text = formatter.stringFromDate(activity.time)
            cell.textLabel?.text = label
        } else if let patrolLog = model as? PatrolLog {
            if let vessel = patrolLog.agencyVessel {
                label += vessel.name + " "
            }
            label += "Patrol Log"
            cell.textLabel?.text = label
            cell.detailTextLabel?.text = formatter.stringFromDate(patrolLog.date)
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var activity = items[indexPath.row]
        if self.searchController.active {
            activity = filteredObjects[indexPath.row]
        } 

        var controller:UIViewController
        if activity is Activity {
            switch (activity as! Activity).type {
            case Activity.Types.CDFW_COMM:
                controller = UIStoryboard(name: "CDFWCommercialContact", bundle: nil).instantiateInitialViewController() as! UINavigationController
            case Activity.Types.CDFW_REC:
                controller = UIStoryboard(name: "CDFWRecContact", bundle: nil).instantiateInitialViewController() as! UINavigationController
            case Activity.Types.NPS:
                controller = UIStoryboard(name: "NPSContact", bundle: nil).instantiateInitialViewController() as! UINavigationController
            default:
                controller = UIStoryboard(name: "ActivityLog", bundle: nil).instantiateInitialViewController() as! UINavigationController
            }
            let form = (controller as! UINavigationController).viewControllers[0] as! ActivityFormTableViewController
            form.activity = activity as! Activity
            form.allowEditing = false
            self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
            DataSync.manager.disableSync()
            self.presentViewController(controller, animated: true, completion: nil)
        } else {
            if let tabs = self.tabBarController as? EFinsTabBarController {
                if tabs.isDisplayingEditablePatrol() {
                    alert("Close Active Patrol", message: "You are currently editing a patrol in the Patrol tab. Please save and close it before continuing.", view: self)
                } else {
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
                    DataSync.manager.disableSync()
                    tabs.displayPatrol(activity as! PatrolLog, returnToLogbook: true)
                }
            }
//            controller = UIStoryboard(name: "PatrolLog", bundle: nil).instantiateInitialViewController() as! UISplitViewController
//            let sidebar = controller.childViewControllers[0].childViewControllers[0] as! PatrolLogSidebarTableViewController
//            sidebar.patrolLog = activity as! PatrolLog
////            sidebar.allowEditing = false
        }
    }

    
    // MARK: - Navigation

    @IBAction func unwindNewContactPopup(sender: UIStoryboardSegue) {
        let tvc = sender.sourceViewController as! UITableViewController
//        let popover = tvc.popoverPresentationController
        let table = tvc.tableView
        if let idx = table.indexPathForSelectedRow {
            var storyboard:UIStoryboard
            var isPatrol = false
            switch idx.row {
                case 0:
                    isPatrol = true
                    storyboard = UIStoryboard(name: "PatrolLog", bundle: nil)
                case 1:
                    storyboard = UIStoryboard(name: "CDFWCommercialContact", bundle: nil)
                case 2:
                    storyboard = UIStoryboard(name: "CDFWRecContact", bundle: nil)
                case 3:
                    storyboard = UIStoryboard(name: "ActivityLog", bundle: nil)
                default:
                    storyboard = UIStoryboard(name: "NPSContact", bundle: nil)
            }
            if isPatrol {
                tvc.dismissViewControllerAnimated(false, completion: nil)
                if let tabs = self.tabBarController as? EFinsTabBarController {
                    if tabs.isDisplayingEditablePatrol() {
                        alert("Close Active Patrol", message: "You are currently editing a patrol in the Patrol tab. Please save and close it before continuing.", view: self)
                    } else {
                        DataSync.manager.disableSync()
                        tabs.startNewPatrol()
                    }
                }
            } else {
                if let tabBar = self.tabBarController as? EFinsTabBarController {
                    tvc.dismissViewControllerAnimated(false, completion: nil)
                    if tabBar.isDisplayingEditablePatrol() {
                        alert("Close Active Patrol", message: "You are currently editing a patrol in the Patrol tab. Please save and close it before continuing, or log activity as part of the patrol.", view: self)
                    } else {
                        let controller = storyboard.instantiateInitialViewController()
                        tvc.dismissViewControllerAnimated(false, completion: nil)
                        DataSync.manager.disableSync()
                        self.presentViewController(controller! as UIViewController, animated: true, completion: nil)
                    }
                } else {
                    print("Could not find eFinsTabBarController")
                    print(self.splitViewController?.tabBarController)
                }
            }
        } else {
            tvc.dismissViewControllerAnimated(true, completion: nil)
        }
    }

}
