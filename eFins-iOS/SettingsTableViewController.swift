//
//  SettingsTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/21/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Alamofire

class SettingsTableViewController: UITableViewController, DataSyncDelegate {

    @IBOutlet weak var loginCell: UITableViewCell!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var mapDownloadButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!
    @IBOutlet weak var mapDataCell: UITableViewCell!
    @IBOutlet weak var mapLabel: UILabel!
    @IBOutlet weak var syncButton: UIButton!
    @IBOutlet weak var logbookSyncLabel: UILabel!
    @IBOutlet weak var logbookSyncActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var photosSyncProgressLabel: UILabel!
    @IBOutlet weak var photosSyncActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var photosSyncStatusLabel: UILabel!
    
    let chartbackgroundSession = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.efins.eFins.chart-background")
    let basemapBackgroundSession = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.efins.eFins.basemap-background")
    var chartManager:Alamofire.Manager!
    var basemapManager:Alamofire.Manager!
    var downloading = false
    var chartBytesRead = 0
    var basemapBytesRead = 0
    var totalBytes = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.chartManager = Alamofire.Manager(configuration: chartbackgroundSession)
        self.basemapManager = Alamofire.Manager(configuration: basemapBackgroundSession)

        if let user = (UIApplication.sharedApplication().delegate as! AppDelegate).getUser() {
            self.loginCell.textLabel?.text = "Signed in as \(user.name)"
        }
        updateDisplay()
        DataSync.manager.delegate = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        updateDisplay()
        println(DataSync.manager.lastSync)
    }
    
    
    @IBAction func signOut(sender: AnyObject) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.signOut()
    }
    
    override func viewWillAppear(animated: Bool) {
        updateDisplay()
    }
    
    func renderPhotosStatus() {
    }
    
    func renderLogbookSyncStatus() {
        if DataSync.manager.syncInProgress {
            self.logbookSyncLabel.text = "syncing"
            self.logbookSyncActivityIndicator.startAnimating()
        } else {
            self.logbookSyncActivityIndicator.stopAnimating()
            if let lastSync = DataSync.manager.lastSync {
                self.logbookSyncLabel.text = "Synced \(timeAgoSinceDate(lastSync, true).lowercaseString)"
            } else {
                self.logbookSyncLabel.text = " "
            }
        }
    }
    
    func dataSyncDidStart() {
        self.syncButton.enabled = false
        self.logbookSyncActivityIndicator.startAnimating()
        self.logbookSyncLabel.text = "syncing"
    }
    
    func dataSyncDidStartPull() {
        self.logbookSyncLabel.text = "fetching data"
    }
    
    func dataSyncDidStartPush() {
        self.logbookSyncLabel.text = "publishing your data"
    }
    
    func dataSyncDidComplete(success: Bool) {
        println("did complete")
        if success {
            if let lastSync = DataSync.manager.lastSync {
                self.logbookSyncLabel.text = "Synced \(timeAgoSinceDate(lastSync, true).lowercaseString)"
            }
        } else {
            if DataSync.manager.reachability.isReachable() {
                self.logbookSyncLabel.text = "error occured"
            } else {
                self.logbookSyncLabel.text = "must be connected to the internet"
            }
        }
        self.syncButton.enabled = true
        self.logbookSyncActivityIndicator.stopAnimating()
    }
    
    @IBAction func syncNow(sender: AnyObject) {
        DataSync.manager.sync()
        self.renderLogbookSyncStatus()
        self.renderPhotosStatus()
    }
    
    func updateDisplay() {
        if tilesExist() {
            self.progress.hidden = true
            self.mapDownloadButton.hidden = false
            self.mapDownloadButton.enabled = true
            self.mapDownloadButton.setTitle("Clear Map Data", forState: UIControlState.Normal)
            self.mapDownloadButton.tintColor = UIColor.redColor()
            self.mapLabel.text = "Map data saved to device"
        } else {
            if downloading {
                self.progress.hidden = false
                self.mapDownloadButton.hidden = true
                let msg = "Downloading Map Data (\((basemapBytesRead + chartBytesRead) / 1000 / 1000) MB / \(totalBytes / 1000 / 1000) MB)"
                self.mapLabel.text = msg
            } else {
                self.mapDownloadButton.setTitle("Download Map Data", forState: UIControlState.Normal)
                self.mapDownloadButton.enabled = true
                self.progress.hidden = true
                self.mapDownloadButton.tintColor = self.signOutButton.tintColor
                self.mapLabel.text = "Map Data not yet loaded"
            }
        }
        self.renderPhotosStatus()
        self.renderLogbookSyncStatus()
        self.mapDownloadButton.sizeToFit()
    }

    @IBAction func downloadMaps(sender: AnyObject) {
        if !tilesExist() && !downloading {
            self.mapDownloadButton.enabled = false
            self.downloading = true
            self.totalBytes = 0
            self.chartBytesRead = 0
            self.basemapBytesRead = 0
            var chartsSizeFiguredOut = false
            var basemapSizeFiguredOut = false
            var chartsDone = false
            var basemapDone = false
            self.chartManager.download(.GET, CHART_MBTILES, destination: { (temporaryURL, response) in
                return NSURL(fileURLWithPath: chartPath()!, isDirectory: false)!
                })
                .progress { (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
                    if self.chartBytesRead == 0 {
                        self.totalBytes += Int(totalBytesExpectedToRead)
                    }
                    self.chartBytesRead = Int(totalBytesRead)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.updateProgress()
                    })
                }
                .response { (request, response, _, error) in
                    if error != nil {
                        println(error)
                        alert("Error Downloading", "\(error?.description)", self)
                        self.downloading = false
                        dispatch_async(dispatch_get_main_queue(), {
                            self.updateDisplay()
                        })
                    } else {
                        chartsDone = true
                        if chartsDone && basemapDone {
                            self.downloading = false
                            dispatch_async(dispatch_get_main_queue(), {
                                self.updateDisplay()
                            })
                        }
                    }
            }
            
            self.basemapManager.download(.GET, BASEMAP_MBTILES, destination: { (temporaryURL, response) in
                return NSURL(fileURLWithPath: basemapPath()!, isDirectory: false)!
            })
                .progress { (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
                    if self.basemapBytesRead == 0 {
                        self.totalBytes += Int(totalBytesExpectedToRead)
                    }
                    self.basemapBytesRead = Int(totalBytesRead)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.updateProgress()
                    })
                }
                .response { (request, response, _, error) in
                    if error != nil {
                        println(error)
                        alert("Error Downloading", "\(error?.description)", self)
                        self.downloading = false
                        dispatch_async(dispatch_get_main_queue(), {
                            self.updateDisplay()
                        })
                    } else {
                        basemapDone = true
                        if chartsDone && basemapDone {
                            self.downloading = false
                            dispatch_async(dispatch_get_main_queue(), {
                                self.updateDisplay()
                            })
                        }
                    }
            }
        } else if tilesExist() {
            confirm("Delete Map Data", "Are you sure you want to clear map data? You will not be able to view maps until you download the data again.", self) { () in
                let fileManager = NSFileManager.defaultManager()
                fileManager.removeItemAtPath(chartPath()!, error: nil)
                fileManager.removeItemAtPath(basemapPath()!, error: nil)
                self.updateDisplay()
            }
        }
    }
    
    func updateProgress() {
        self.progress.hidden = false
        let msg = "Downloading Map Data (\((basemapBytesRead + chartBytesRead) / 1000 / 1000) MB / \(totalBytes / 1000 / 1000) MB)"
        self.mapLabel.text = msg
        self.progress.setProgress(Float(self.chartBytesRead + self.basemapBytesRead) / Float(self.totalBytes), animated: true)
    }
    
}
