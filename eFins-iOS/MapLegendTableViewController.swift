//
//  MapLegendTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/19/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit

class MapLegendTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }


    @IBAction func emptyOfflineCache(sender: AnyObject) {
        if let map = (self.splitViewController?.viewControllers[1] as? UINavigationController)?.viewControllers[0] as? MapViewController {
            confirm("Clear offline cache", "Map data will have to be downloaded again before you can use maps offline.", self) { () in
                map.emptyCache()
            }
        }
    }


}
