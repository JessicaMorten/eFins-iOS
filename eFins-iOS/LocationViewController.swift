//
//  LocationViewController.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 5/28/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//


import UIKit
import Foundation

class LocationViewController: UIViewController, UIAlertViewDelegate, RMTileCacheBackgroundDelegate {
    
    var map:RMMapView!
    var thematicLayer:RMMBTilesSource?
    var charts:RMMBTilesSource!
    var reachability: Reachability!
    let southWestConstraints = CLLocationCoordinate2DMake(32, -123)
    let northEastConstraints = CLLocationCoordinate2DMake(35.42, -116.5)
    // should be 12, but setting to 10 for testing
    //    let maxOfflineZoom = UInt(10)
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var popupLabel: UILabel!
    var didLoadTiles = false
    
    @IBOutlet weak var mapSegmentControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.popupLabel.alpha = 0
        let uri = NSURL(string: SERVER_ROOT)
        let host = uri?.host ?? ""
        self.reachability = Reachability(hostname: host)
        
        RMConfiguration.sharedInstance().accessToken = "pk.eyJ1IjoidW5kZXJibHVld2F0ZXJzIiwiYSI6IjMzZ215RTQifQ.u6Gb_-kNfvaxiHdd9eJEEA"
        
        // configure map tile source based on previous metadata if available
        //        if let tileJSON = cachedJSON() {
        //            self.thematicLayer = RMMapboxSource(tileJSON: tileJSON)
        //        } else {
        //            self.thematicLayer = RMMapboxSource(mapID: "underbluewaters.i9hjn51p")
        //        }
        
        if loadTiles() {
            initMap()
        } else {
            alert("Map Tiles Not Cached", "To use maps you need to first download data layers from the settings tab.", self)
        }
    }
    
    func loadTiles() -> Bool {
        if tilesExist() {
            self.charts = RMMBTilesSource(tileSetURL: NSURL(fileURLWithPath: chartPath()!, isDirectory: false))
            self.thematicLayer = RMMBTilesSource(tileSetURL: NSURL(fileURLWithPath: basemapPath()!, isDirectory: false))
            return true
        } else {
            return false
        }
    }
    
    func initMap() {
        self.map = RMMapView(frame: view.bounds, andTilesource: self.thematicLayer)
        self.backgroundView.insertSubview(map, atIndex: 0)

        map.zoom = 9
        map.maxZoom = 15
        map.minZoom = 8
        map.centerCoordinate = CLLocationCoordinate2D(latitude: 34.007, longitude: -119.829)
        map.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        map.setConstraintsSouthWest(southWestConstraints, northEast: northEastConstraints)
        
        map.userTrackingMode = RMUserTrackingModeNone
        self.navigationItem.rightBarButtonItem = RMUserTrackingBarButtonItem(mapView: map)
        self.didLoadTiles = true
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.didLoadTiles {
            self.mapSegmentControl.enabled = true
        } else {
            if loadTiles() {
                initMap()
                self.mapSegmentControl.enabled = true
            } else {
                self.mapSegmentControl.enabled = false
                alert("Map Tiles Not Cached", "To use maps you need to first download data layers from the settings tab.", self)
            }
        }
    }
    
    func hasCache() -> Bool {
        if let cached = cachedJSON() {
            return true
        } else {
            return false
        }
    }
    
    
    
    func cachedJSON() -> String? {
        return NSUserDefaults.standardUserDefaults().objectForKey("thematicJSON") as? String
    }
    
    func emptyCache() {
        map.removeAllCachedImages()
        
        NSUserDefaults.standardUserDefaults().removeObjectForKey("thematicJSON")
        
        UIAlertView(title: "Offline Cache Cleared",
            message: "You will not be able to use the map offline until map data is downloaded",
            delegate: nil,
            cancelButtonTitle: "OK").show()
        
        map.reloadTileSource(map.tileSource)
    }
    
    func promptDownload() {
        if (map == nil) {
            return
        }
        
        let tileCount = map.tileCache.tileCountForSouthWest(southWestConstraints,
            northEast: northEastConstraints,
            minZoom: UInt(map.minZoom),
            maxZoom: UInt(map.maxZoom))
        
        let message: String = {
            let formatter = NSNumberFormatter()
            formatter.usesGroupingSeparator = true
            formatter.groupingSeparator = ","
            var message = "Download \(formatter.stringFromNumber(tileCount)!) map tiles now?"
            if (tileCount > 1000) {
                message += " Caching may take a long time. It is recommended"
                message += " that you connect to Wi-Fi and plug in the device."
            }
            return message
            }()
        
        let alert = UIAlertView(title: "Download?",
            message: message,
            delegate: self,
            cancelButtonTitle: "Cancel",
            otherButtonTitles: "Download").show()
    }
    
    // MARK: - Alert Delegate
    
    @IBAction func layerChange(sender: AnyObject) {
        if self.didLoadTiles {
            switch self.mapSegmentControl.selectedSegmentIndex {
            case 0:
                self.map.tileSource = self.thematicLayer
            case 1:
                //            self.map.adjustTilesForRetinaDisplay = true
                self.map.tileSource = self.charts
            default:
                //            self.map.adjustTilesForRetinaDisplay = true
                self.map.tileSource = self.charts
            }
        }
    }
    
}
