//
//  PatrolLogSidebarTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/12/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class PatrolLogSidebarTableViewController: UITableViewController {

    var patrolLog:PatrolLog!
    var isNew = true
    var allowEditing = true
    var initialSelectionSet = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancelTapped")

        if patrolLog == nil {
            patrolLog = PatrolLog()
            self.allowEditing = true
            let realm = RLMRealm.defaultRealm()
            realm.beginWriteTransaction()
            patrolLog.date = NSDate()
            if let user = (UIApplication.sharedApplication().delegate as! AppDelegate).getUser() {
                patrolLog.user = user
            }
            realm.addObject(self.patrolLog)
            realm.commitWriteTransaction()
        } else {
            allowEditing = false
        }
        let controller:UINavigationController = (self.navigationController?.parentViewController as! UISplitViewController).viewControllers[1] as! UINavigationController
        controller.viewControllers[0].setValue(self.patrolLog, forKey: "patrolLog")
        controller.viewControllers[0].setValue(allowEditing, forKey: "allowEditing")
        controller.viewControllers[0].setValue(isNew, forKey: "isNew")


        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewDidAppear(animated: Bool) {
        if initialSelectionSet == false {
            initialSelectionSet = true
            self.tableView.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: false, scrollPosition: UITableViewScrollPosition.Top)
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

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let controller = segue.destinationViewController as! UINavigationController
        (controller.viewControllers[0]).setValue(self.patrolLog, forKey: "patrolLog")
        (controller.viewControllers[0]).setValue(self.allowEditing, forKey: "allowEditing")
        if controller.viewControllers[0] is PatrolLogGeneralFormTableViewController {
            (controller.viewControllers[0]).setValue(self.isNew, forKey: "isNew")
        }

    }
    
    // MARK: - Actions
}
