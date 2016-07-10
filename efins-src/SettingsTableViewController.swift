//
//  SettingsTableViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/21/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Alamofire
import SSZipArchive

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
    @IBOutlet weak var versionLabel: UILabel!
    
    let chartbackgroundSession = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.efins.eFins.chart-background")
    let basemapBackgroundSession = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.efins.eFins.basemap-background")
    var chartManager:Alamofire.Manager!
    var basemapManager:Alamofire.Manager!
    var downloading = false
    var unpacking = false
    var chartBytesRead = 0
    var basemapBytesRead = 0
    var totalBytes = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.chartManager = Alamofire.Manager(configuration: chartbackgroundSession)
        self.basemapManager = Alamofire.Manager(configuration: basemapBackgroundSession)
        print("manager \(self.chartManager)")
        if let user = (UIApplication.sharedApplication().delegate as! AppDelegate).getUser() {
            self.loginCell.textLabel?.text = "Signed in as \(user.name)"
        }
        self.versionLabel.text = "eFins " + (NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String);
        updateDisplay()
        DataSync.manager.delegate = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        updateDisplay()
        print(DataSync.manager.lastSync)
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
                self.logbookSyncLabel.text = "Synced \(timeAgoSinceDate(lastSync, numericDates: true).lowercaseString)"
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
        print("did complete")
        if success {
            if let lastSync = DataSync.manager.lastSync {
                self.logbookSyncLabel.text = "Synced \(timeAgoSinceDate(lastSync, numericDates: true).lowercaseString)"
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
            } else if unpacking {
                self.progress.hidden = false
                self.mapDownloadButton.hidden = true
                let msg = "Unpacking Map Data (\((basemapBytesRead + chartBytesRead) / 1000 / 1000) MB / \(totalBytes / 1000 / 1000) MB)"
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
            print("going to download")
            let fileManager = NSFileManager.defaultManager()
            if fileManager.fileExistsAtPath(chartPath()!) {
                print("removing charts")
                do {
                    try fileManager.removeItemAtPath(chartPath()!)
                } catch _ {
                }
            }
            if fileManager.fileExistsAtPath(basemapPath()!) {
                print("removing basemaps")
                do {
                    try fileManager.removeItemAtPath(basemapPath()!)
                } catch _ {
                }
            }
            self.chartManager.session.getTasksWithCompletionHandler { (tasks, _, _) in
                for item in tasks {
                    print("item \(item)")
                    if let task = item as? NSURLSessionDownloadTask {
                        print("cancelling")
                        task.cancel()
                    }
                }
            }
            self.basemapManager.session.getTasksWithCompletionHandler { (tasks, _, _) in
                for item in tasks {
                    print("item \(item)")
                    if let task = item as? NSURLSessionDownloadTask {
                        print("cancelling")
                        task.cancel()
                    }
                }
            }
            self.mapDownloadButton.enabled = false
            self.downloading = true
            self.totalBytes = 0
            self.chartBytesRead = 0
            self.basemapBytesRead = 0
            var chartsSizeFiguredOut = false
            var basemapSizeFiguredOut = false
            var chartsDone = false
            var basemapDone = false
            print("doing chartManager")
            self.chartManager.download(.GET, CHART_MBTILES, destination: { (temporaryURL, response) in
                return NSURL(fileURLWithPath: chartPath()!, isDirectory: false)
            })
                .progress { (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
                    print("progress, charts")
                    if self.chartBytesRead == 0 {
                        self.totalBytes += Int(totalBytesExpectedToRead)
                    }
                    print("\(self.totalBytes) read")
                    self.chartBytesRead = Int(totalBytesRead)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.updateProgress()
                    })
                }
                .response { (request, response, _, error) in
                    if error != nil {
                        print(error)
                        alert("Error Downloading", message: "\(error?.description)", view: self)
                        self.downloading = false
                        dispatch_async(dispatch_get_main_queue(), {
                            self.updateDisplay()
                        })
                    } else {
                        print("charts downloaded")
                        chartsDone = true
                        if chartsDone && basemapDone {
                            self.unpack()
                        }
                    }
            }
            print("doing basemapManager")
            self.basemapManager.download(.GET, BASEMAP_MBTILES, destination: { (temporaryURL, response) in
                return NSURL(fileURLWithPath: basemapPath()!, isDirectory: false)
            })
                .progress { (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
                    print("progress, basemap")
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
                        print(error)
                        alert("Error Downloading", message: "\(error?.description)", view: self)
                        self.downloading = false
                        dispatch_async(dispatch_get_main_queue(), {
                            self.updateDisplay()
                        })
                    } else {
                        print("basemaps downloaded")
                        basemapDone = true
                        if chartsDone && basemapDone {
                            self.unpack()
                                                    }
                    }
            }
        } else if tilesExist() {
            print("tiles exist, delete?")
            confirm("Delete Map Data", message: "Are you sure you want to clear map data? You will not be able to view maps until you download the data again.", view: self) { () in
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtPath(chartPath()!)
                } catch _ {
                }
                do {
                    try fileManager.removeItemAtPath(basemapPath()!)
                } catch _ {
                }
                self.updateDisplay()
            }
        }
    }
    
    
    func unpack () {
        self.downloading = false
        self.unpacking = true
        SSZipArchive.unzipFileAtPath(basemapPath(), toDestination: basemapTilesPath(), progressHandler: { (name: String!, zipInfo, entryNumber: Int, total: Int) in
                NSLog("\(basemapPath()): \(entryNumber) of \(total)")
        }, completionHandler: { (path: String!, succeeded, error: NSError!) in
                NSLog("Done with \(path)")
                dispatch_async(dispatch_get_main_queue(), {
                    self.updateDisplay()
                })

        })
        SSZipArchive.unzipFileAtPath(chartPath(), toDestination: chartTilesPath(), progressHandler: { (name: String!, zipInfo, entryNumber: Int, total: Int) in
            NSLog("\(chartPath()): \(entryNumber) of \(total)")
            }, completionHandler: { (path: String!, succeeded, error: NSError!) in
                NSLog("Done with \(path)")
                dispatch_async(dispatch_get_main_queue(), {
                    self.updateDisplay()
                })
                
        })

    }
    
    func updateProgress() {
        self.progress.hidden = false
        let msg = "Downloading Map Data (\((basemapBytesRead + chartBytesRead) / 1000 / 1000) MB / \(totalBytes / 1000 / 1000) MB)"
        self.mapLabel.text = msg
        self.progress.setProgress(Float(self.chartBytesRead + self.basemapBytesRead) / Float(self.totalBytes), animated: true)
    }
    
}