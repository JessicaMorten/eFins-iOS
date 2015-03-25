//
//  NewEntryPopoverTableViewController.swift
//  
//
//  Created by CHAD BURT on 3/25/15.
//
//

import UIKit

class NewEntryPopoverTableViewController: UITableViewController {

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            self.parentViewController?.performSegueWithIdentifier("ActivityLog", sender: self.parentViewController)
        }
    }

}
