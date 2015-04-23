//
//  DayDatePickerTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit

class DayDatePickerTableViewController: UITableViewController {
    
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    var date:NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.date == nil {
            self.date = NSDate()
        }
        self.datePicker.date = self.date!
    }
    
    
    @IBAction func datePickerChanged(sender: AnyObject) {
        self.date = self.datePicker.date
    }
    
}
