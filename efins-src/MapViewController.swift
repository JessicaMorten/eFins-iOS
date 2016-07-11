//
//  MapViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/18/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Foundation
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, UIAlertViewDelegate {
    
    var map:MKMapView!
    //var thematicLayer:RMMBTilesSource?
    //var charts:RMMBTilesSource!
    var reachability: Reachability!
    var useSplitView : Bool = true
    let southWestConstraints = CLLocationCoordinate2DMake(32, -123)
    let northEastConstraints = CLLocationCoordinate2DMake(35.42, -116.5)
    // should be 12, but setting to 10 for testing
    //    let maxOfflineZoom = UInt(10)
    @IBOutlet var backgroundView: UIView!
    @IBOutlet weak var popupLabel: UILabel!
    var didLoadTiles = false
    
    @IBOutlet weak var mapSegmentControl: UISegmentedControl!
    
    
    init(splitViewMode: Bool = true) {
        super.init(nibName: nil, bundle: nil)
        useSplitView = splitViewMode
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        return
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.popupLabel.alpha = 0
        let uri = NSURL(string: SERVER_ROOT)
        let host = uri?.host ?? ""
        self.reachability = Reachability(hostname: host)
        
        if useSplitView {
            self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden
        }
        
        
        // configure map tile source based on previous metadata if available
        //        if let tileJSON = cachedJSON() {
        //            self.thematicLayer = RMMapboxSource(tileJSON: tileJSON)
        //        } else {
        //            self.thematicLayer = RMMapboxSource(mapID: "underbluewaters.i9hjn51p")
        //        }
        
        if loadTiles() {
            initMap()
        } else {
            alert("Map Tiles Not Cached", message: "To use maps you need to first download data layers from the settings tab.", view: self)
        }
    }
    
    func loadTiles() -> Bool {
        if tilesExist() {
            NSLog("TILES tilesExist")
            ////self.charts = RMMBTilesSource(tileSetURL: NSURL(fileURLWithPath: chartPath()!, isDirectory: false))
            //self.thematicLayer = RMMBTilesSource(tileSetURL: NSURL(fileURLWithPath: basemapPath()!, isDirectory: false))
            return true
        } else {
            return false
        }
    }
    
    func initMap() {
        self.map = MKMapView(frame: view.bounds)
        self.backgroundView.insertSubview(map, atIndex: 0)
        
        if useSplitView {
            self.map.delegate = self
        }
//        map.zoom = 9
//        map.maxZoom = 15
//        map.minZoom = 8
        map.centerCoordinate = CLLocationCoordinate2D(latitude: 34.007, longitude: -119.829)
        //map.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        //map.setConstraintsSouthWest(southWestConstraints, northEast: northEastConstraints)
        
        map.userTrackingMode = MKUserTrackingMode.None
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
                alert("Map Tiles Not Cached", message: "To use maps you need to first download data layers from the settings tab.", view: self)
            }
        }
    }
    
    
    // We only register as delegate of the map if we are in split view mode, so this won't be triggered there (in location setting view, the parent table view controller acts as delegate)
    func singleTapOnMap(map: MKMapView!, at point: CGPoint) {
//        if let source = self.map.tileSource as? RMInteractiveSource {
//            if source.supportsInteractivity() {
//                var content = source.formattedOutputOfType(RMInteractiveSourceOutputTypeTeaser, forPoint: point, inMapView: map)
//                if content != nil && content.characters.count > 0 {
//                    showPopup(content, point: point)
//                } else {
//                    hidePopup()
//                }
//            }
//        }
    }
    
    func showPopup(content:String, point:CGPoint) {
        self.popupLabel.text = " \(content)　"
        self.popupLabel.sizeToFit()
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
            self.popupLabel.alpha = 1
            }, completion: nil)
    }
    
    func hidePopup() {
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
            self.popupLabel.alpha = 0
            }, completion: nil)
    }
    
    func mapViewRegionDidChange(mapView: RMMapView!) {
        hidePopup()
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