//
//  ActivityLogTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class ActivityLogTableViewController: UITableViewController {

    @IBOutlet weak var locationTableCell: UITableViewCell!
    // TODO: immediately fetch location in background and spin indicator
    @IBOutlet weak var locationActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var dateTableCell: UITableViewCell!

    var date:NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.isNew() {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel,
                target: self, action: "cancel")
            self.locationTableCell.textLabel?.text = "Include Location"
            self.date = NSDate()
            let formatter = getDateFormatter()
            dateTableCell.detailTextLabel?.text = formatter.stringFromDate(self.date!)
        }
    }
    
    // TODO: Implement isNew when model is available
    func isNew() -> Bool {
        return true
    }
    
    // TODO: delete model on cancel
    func cancel() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    
    // MARK: - Navigation

//    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        // Get the new view controller using [segue destinationViewController].
//        // Pass the selected object to the new view controller.
//        let controller = segue.destinationViewController
//    }


    @IBAction func unwindDatePicker(sender: UIStoryboardSegue) {
        let sourceViewController = sender.sourceViewController as DatePickerTableViewController
        self.date = sourceViewController.date
        let formatter = getDateFormatter()
        dateTableCell.detailTextLabel?.text = formatter.stringFromDate(self.date!)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 1 {
            let storyboard = UIStoryboard(name: "DatePicker", bundle: nil)
            let controller:DatePickerTableViewController = storyboard.instantiateInitialViewController() as DatePickerTableViewController
            self.navigationController?.pushViewController(controller, animated: true)
            controller.date = self.date
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
}
