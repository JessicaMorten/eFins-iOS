//
//  ActivityLogTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class ActivityLogTableViewController: UITableViewController, UITextViewDelegate {

    @IBOutlet weak var locationTableCell: UITableViewCell!
    // TODO: immediately fetch location in background and spin indicator
    @IBOutlet weak var locationActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var dateTableCell: UITableViewCell!
    @IBOutlet weak var remarksTextView: UITextView!

    var activity:Activity?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if self.isNew() {
            let realm = RLMRealm.defaultRealm()
            activity = Activity()
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel,
                target: self, action: "cancel")
            self.locationTableCell.textLabel?.text = "Include Location"
            activity?.time = NSDate()
            let formatter = getDateFormatter()
            dateTableCell.detailTextLabel?.text = formatter.stringFromDate(activity!.time)
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
        activity?.time = sourceViewController.date!
        let formatter = getDateFormatter()
        dateTableCell.detailTextLabel?.text = formatter.stringFromDate(activity!.time)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 1 {
            let storyboard = UIStoryboard(name: "DatePicker", bundle: nil)
            let controller:DatePickerTableViewController = storyboard.instantiateInitialViewController() as DatePickerTableViewController
            self.navigationController?.pushViewController(controller, animated: true)
            controller.date = activity!.time
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == "Add any relevant comments here..." {
            textView.text = ""
            textView.textColor = UIColor.blackColor()
        }
        textView.becomeFirstResponder()
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text == "" {
            textView.text = "Add any relevant comments here..."
            textView.textColor = UIColor.lightGrayColor()
            self.activity?.remarks = ""
        } else {
            self.activity?.remarks = textView.text
        }
        textView.resignFirstResponder()
    }

    @IBAction func tapRecognizer(sender:AnyObject) {
        self.hideNotesKeyboard()
    }
    
    func hideNotesKeyboard() {
        self.remarksTextView.endEditing(true)
    }
    
}
