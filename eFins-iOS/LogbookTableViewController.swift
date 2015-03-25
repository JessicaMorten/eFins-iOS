//
//  LogbookTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/25/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit

class LogbookTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    // MARK: - Table view data source

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        println("Preparing for Segue")
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }

}
