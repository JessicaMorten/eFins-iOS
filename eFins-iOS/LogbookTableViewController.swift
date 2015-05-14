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
    
    var activities: RLMResults {
        get {
            return Activity.allObjects().sortedResultsUsingProperty("time", ascending: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.token = RLMRealm.defaultRealm().addNotificationBlock { note, realm in
                println("Got update")
                self.tableView.reloadData()
        }

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(self.activities.count)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        
        let index = UInt(indexPath.row)
        let activity = activities.objectAtIndex(index) as! Activity
        switch activity.type {
            case Activity.Types.LOG:
                cell.textLabel?.text = "Activity Log"
            case Activity.Types.CDFW_REC:
                cell.textLabel?.text = "CDFW Recreational Contact"
            case Activity.Types.CDFW_COMM:
                cell.textLabel?.text = "CDFW Commercial Boarding"
            case Activity.Types.NPS:
                cell.textLabel?.text = "NPS Contact Record"
            default:
                cell.textLabel?.text = "Other"
        }
        let formatter = getDateFormatter()
        cell.detailTextLabel?.text = formatter.stringFromDate(activity.time)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let activity = activities.objectAtIndex(UInt(indexPath.row)) as! Activity
        var controller:UINavigationController
        switch activity.type {
            case Activity.Types.CDFW_COMM:
                controller = UIStoryboard(name: "CDFWCommercialContact", bundle: nil).instantiateInitialViewController() as! UINavigationController
            case Activity.Types.CDFW_REC:
                controller = UIStoryboard(name: "CDFWRecContact", bundle: nil).instantiateInitialViewController() as! UINavigationController
            case Activity.Types.NPS:
                controller = UIStoryboard(name: "NPSContact", bundle: nil).instantiateInitialViewController() as! UINavigationController
            default:
                controller = UIStoryboard(name: "ActivityLog", bundle: nil).instantiateInitialViewController() as! UINavigationController
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
        let form = controller.viewControllers[0] as! ActivityFormTableViewController
        form.activity = activity
        form.allowEditing = false
        self.presentViewController(controller, animated: true, completion: nil)
    }

    
    // MARK: - Navigation

    @IBAction func unwindNewContactPopup(sender: UIStoryboardSegue) {
        println("Unwind")
        let tvc = sender.sourceViewController as! UITableViewController
//        let popover = tvc.popoverPresentationController
        let table = tvc.tableView
        if let idx = table.indexPathForSelectedRow() {
            var storyboard:UIStoryboard
            switch idx.row {
                case 0:
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
            let controller = storyboard.instantiateInitialViewController()
            tvc.dismissViewControllerAnimated(false, completion: nil)
            self.presentViewController(controller as! UIViewController, animated: true, completion: nil)
        } else {
            tvc.dismissViewControllerAnimated(true, completion: nil)
        }
    }

}
