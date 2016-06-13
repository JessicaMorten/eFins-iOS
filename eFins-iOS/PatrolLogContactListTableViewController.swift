//
//  PatrolLogContactListTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/12/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class PatrolLogContactListTableViewController: UITableViewController {

    var patrolLog:PatrolLog!
    var allowEditing = true
    @IBOutlet weak var plusButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.allowEditing == false {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "edit")
        } else {
            self.navigationItem.rightBarButtonItem = self.plusButton
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func edit() {
        if let svc = self.splitViewController {
            if let n = svc.viewControllers[0] as? UINavigationController {
                if let sidebar = n.viewControllers[0] as? PatrolLogSidebarTableViewController {
                    sidebar.toggleEditing(true)
                }
            }
        }
        self.allowEditing = true
        self.navigationItem.rightBarButtonItem = self.plusButton
    }

    // MARK: - Table view data source

    func activities() -> RLMResults {
        return Activity.objectsWhere("patrolLog = %@ AND deletedAt == %@", self.patrolLog, NSDate(timeIntervalSince1970: 0)).sortedResultsUsingProperty("time", ascending: false)
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return Int(activities().count)
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) 
        let index = UInt(indexPath.row)
        let model:AnyObject = self.activities().objectAtIndex(index)
        let formatter = getDateFormatter()
        var label = ""
        if let activity = model as? Activity {
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
                if observedVessel.name.characters.count > 0 {
                    label += " (\(observedVessel.name))"
                } else if observedVessel.registration.characters.count > 0 {
                    label += " (\(observedVessel.registration))"
                }
            }
            cell.detailTextLabel?.text = formatter.stringFromDate(activity.time)
            cell.textLabel?.text = label
        }
        return cell
    }
    
    @IBAction func unwindNewContactPopup(sender: UIStoryboardSegue) {
        let tvc = sender.sourceViewController as! UITableViewController
        let table = tvc.tableView
        if let idx = table.indexPathForSelectedRow {
            var storyboard:UIStoryboard
            switch idx.row {
            case 0:
                storyboard = UIStoryboard(name: "ActivityLog", bundle: nil)
            case 1:
                storyboard = UIStoryboard(name: "CDFWCommercialContact", bundle: nil)
            case 2:
                storyboard = UIStoryboard(name: "CDFWRecContact", bundle: nil)
            default:
                storyboard = UIStoryboard(name: "ActivityLog", bundle: nil)
            }
            let controller = storyboard.instantiateInitialViewController()
            tvc.dismissViewControllerAnimated(false, completion: nil)
            if let nc = controller as? UINavigationController {
                if let activityForm = nc.viewControllers[0] as? ActivityFormTableViewController {
                    activityForm.patrolLog = self.patrolLog
                }
            }
            
            self.presentViewController(controller as! UIViewController, animated: true, completion: nil)
        } else {
            tvc.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let activity = activities().objectAtIndex(UInt(indexPath.row))
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
            self.presentViewController(controller, animated: true, completion: nil)
        } else {
            if let tabs = self.tabBarController as? EFinsTabBarController {
                if tabs.isDisplayingEditablePatrol() {
                    alert("Close Active Patrol", message: "You are currently editing a patrol in the Patrol tab. Please save and close it before continuing.", view: self)
                } else {
                    self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
                    tabs.displayPatrol(activity as! PatrolLog)
                }
            }
            //            controller = UIStoryboard(name: "PatrolLog", bundle: nil).instantiateInitialViewController() as! UISplitViewController
            //            let sidebar = controller.childViewControllers[0].childViewControllers[0] as! PatrolLogSidebarTableViewController
            //            sidebar.patrolLog = activity as! PatrolLog
            ////            sidebar.allowEditing = false
        }
    }

    
    override func viewWillAppear(animated: Bool) {
        self.tableView.reloadData()
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
