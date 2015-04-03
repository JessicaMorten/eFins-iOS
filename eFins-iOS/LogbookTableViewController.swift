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
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        
        let index = UInt(indexPath.row)
        let activity = activities.objectAtIndex(index) as Activity
        switch activity.type {
            case "activityLog":
                cell.textLabel?.text = "Activity Log"
            default:
                cell.textLabel?.text = "Other"
        }
        let formatter = getDateFormatter()
        cell.detailTextLabel?.text = formatter.stringFromDate(activity.time)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let activity = activities.objectAtIndex(UInt(indexPath.row)) as Activity
        if activity.type == "activityLog" {
            self.performSegueWithIdentifier("ShowActivityLog", sender: activity)
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowActivityLog" {
            let activity = sender as Activity
            let controller = (segue.destinationViewController as UINavigationController).viewControllers[0]
                as ActivityLogTableViewController
            controller.activity = activity
        }
        
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }

}
