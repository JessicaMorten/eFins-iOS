//
//  LogbookTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/25/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class LogbookTableViewController: UITableViewController {

    var token:RLMNotificationToken?
    
    var _activities: RLMResults {
        get {
            return Activity.allObjects().sortedResultsUsingProperty("time", ascending: false)
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
            var patrolLogs = PatrolLog.allObjects().sortedResultsUsingProperty("date", ascending: false)
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

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.tableView.reloadData()
        DataSync.manager.enableSync()
    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        let index = indexPath.row
        let model = items[index]
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
                if count(observedVessel.name) > 0 {
                    label += " (\(observedVessel.name))"
                } else if count(observedVessel.registration) > 0 {
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
        let activity = items[indexPath.row]
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
                    alert("Close Active Patrol", "You are currently editing a patrol in the Patrol tab. Please save and close it before continuing.", self)
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
        println("unwindNew from main")
        let tvc = sender.sourceViewController as! UITableViewController
//        let popover = tvc.popoverPresentationController
        let table = tvc.tableView
        if let idx = table.indexPathForSelectedRow() {
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
                        alert("Close Active Patrol", "You are currently editing a patrol in the Patrol tab. Please save and close it before continuing.", self)
                    } else {
                        DataSync.manager.disableSync()
                        tabs.startNewPatrol()
                    }
                }
            } else {
                if let tabBar = self.splitViewController?.tabBarController as? EFinsTabBarController {
                    tvc.dismissViewControllerAnimated(false, completion: nil)
                    if tabBar.isDisplayingEditablePatrol() {
                        alert("Close Active Patrol", "You are currently editing a patrol in the Patrol tab. Please save and close it before continuing, or log activity as part of the patrol.", self)
                    } else {
                        let controller = storyboard.instantiateInitialViewController()
                        tvc.dismissViewControllerAnimated(false, completion: nil)
                        DataSync.manager.disableSync()
                        self.presentViewController(controller as! UIViewController, animated: true, completion: nil)
                    }
                } else {
                    println("Could not find eFinsTabBarController")
                    println(self.splitViewController?.tabBarController)
                }
            }
        } else {
            tvc.dismissViewControllerAnimated(true, completion: nil)
        }
    }

}
