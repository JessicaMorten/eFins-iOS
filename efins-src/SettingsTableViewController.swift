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
import NVHTarGzip

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
    @IBOutlet weak var loginNameLabel: UILabel!
    
    let tilebackgroundSession = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.efins.eFins.chart-background")
    //let basemapBackgroundSession = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.efins.eFins.basemap-background")
    var tileManager:Alamofire.Manager!
    //var basemapManager:Alamofire.Manager!
    var downloading = false
    var unpacking = false
    var bytesRead = 0
    var totalBytes = 0
    var nFilesUnpacked = 0
    var nFiles = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tileManager = Alamofire.Manager(configuration: tilebackgroundSession)
        print("manager \(self.tileManager)")
        if let user = (UIApplication.sharedApplication().delegate as! AppDelegate).getUser() {
            self.loginNameLabel.text = "Signed in as \(user.name)"
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
                let msg = "Downloading Map Data (\(self.bytesRead / 1000 / 1000) MB / \(self.totalBytes / 1000 / 1000) MB)"
                self.mapLabel.text = msg
            } else if unpacking {
                self.progress.hidden = false
                self.mapDownloadButton.hidden = true
                let msg = "Unpacking Map Data..."
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
//            if fileManager.fileExistsAtPath(tilePath()!) {
//                self.unpack()
//                return
//            }

//            if fileManager.fileExistsAtPath(chartPath()!) {
//                print("removing charts")
//                do {
//                    try fileManager.removeItemAtPath(chartPath()!)
//                } catch _ {
//                }
//            }
//            if fileManager.fileExistsAtPath(basemapPath()!) {
//                print("removing basemaps")
//                do {
//                    try fileManager.removeItemAtPath(basemapPath()!)
//                } catch _ {
//                }
//            }
            self.tileManager.session.getTasksWithCompletionHandler { (tasks, _, _) in
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
            self.bytesRead = 0
            var chartsSizeFiguredOut = false
            var basemapSizeFiguredOut = false
            var chartsDone = false
            var basemapDone = false
            print("doing tileManager")
            self.tileManager.download(.GET, TILES_URL, destination: { (temporaryURL, response) in
                return NSURL(fileURLWithPath: tilePath()!, isDirectory: false)
            })
                .progress { (bytesRead, totalBytesRead, totalBytesExpectedToRead) in
                    print("progress, tiles")
//                    self.totalBytes = Int(totalBytesExpectedToRead)
//                    self.bytesRead = Int(totalBytesRead)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.updateProgress(totalBytesRead, tot: totalBytesExpectedToRead)
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
                        print("tiles downloaded, starting unpack")
                        self.unpack()
                    }
            }
    } else if tilesExist() {
            print("tiles exist, delete?")
            confirm("Delete Map Data", message: "Are you sure you want to clear map data? You will not be able to view maps until you download the data again.", view: self) { () in
                //**************************
                //return
                //*************************
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtPath(tilePath()!)
                } catch _ {
                }
                self.updateDisplay()
            }
        }
    }
    
    
    func unpack () {
        self.downloading = false
        self.unpacking = true
        let cachePath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] as? String
        
    
        updateDisplay()
        try! NVHTarGzip.sharedInstance().unTarGzipFileAtPath(tilePath(), toPath: cachePath)
        
//        let progress = NSProgress(totalUnitCount: 1)
//        let keyPath = NSStringFromSelector(Selector("updateProgress"))
//        progress.addObserver(self, forKeyPath: keyPath, options: NSKeyValueObservingOptions.Initial, context: nil)
//        progress.becomeCurrentWithPendingUnitCount(1)
//        NVHTarGzip.sharedInstance().unTarGzipFileAtPath(tilePath(), toPath: cachePath,
        
//        try! DCTar.decompressFileAtPath(tilePath(), toPath: cachePath)
        
//        SSZipArchive.unzipFileAtPath(tilePath(), toDestination: cachePath, progressHandler: { (name: String!, zipInfo, entryNumber: Int, total: Int) in
//                NSLog("\(tilePath()): \(entryNumber) of \(total)")
//            if (entryNumber % 100) == 0 {
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.updateUnpack(entryNumber, tot: total)
//                })
//            }
//        }, completionHandler: { (path: String!, succeeded, error: NSError!) in
//                NSLog("Done with \(path)")
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.updateDisplay()
//                })
//
//        })
    }
    
    func updateProgress(n: Int64, tot: Int64) {
        self.progress.hidden = false
        let msg = "Downloading Map Data (\(n / 1000 / 1000) MB / \(tot / 1000 / 1000) MB)"
        self.mapLabel.text = msg
        self.progress.setProgress(Float(n) / Float(tot), animated: true)
    }
    
    
    func updateUnpack(unpacked: Int, tot: Int) {
        self.progress.hidden = false
        let msg = "Unpacking Map Data: \(unpacked) files of \(tot) unpacked"
        self.mapLabel.text = msg
        self.progress.setProgress(Float(unpacked) / Float(tot), animated: true)
    }
    
}