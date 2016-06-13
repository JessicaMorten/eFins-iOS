//
//  NewContactPopupTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit

class NewContactPopupTableViewController: UITableViewController {

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("UnwindNewContactPopup", sender: self)
    }

}
