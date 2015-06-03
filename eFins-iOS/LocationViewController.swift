//
//  LocationViewController.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 5/29/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import UIKit

class LocationViewController: UIViewController {
    
    var map:RMMapView!
    var thematicLayer:RMMBTilesSource?
    var charts:RMMBTilesSource!
    
    let southWestConstraints = CLLocationCoordinate2DMake(32, -123)
    let northEastConstraints = CLLocationCoordinate2DMake(35.42, -116.5)
    
    // should be 12, but setting to 10 for testing
    //    let maxOfflineZoom = UInt(10)
    var backgroundView: UIView!
    
    
    func configureBackgroundView(bView: UIView) {
        backgroundView = bView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let uri = NSURL(string: SERVER_ROOT)
        let host = uri?.host ?? ""
        RMConfiguration.sharedInstance().accessToken = "pk.eyJ1IjoidW5kZXJibHVld2F0ZXJzIiwiYSI6IjMzZ215RTQifQ.u6Gb_-kNfvaxiHdd9eJEEA"
    }
    
    
    func initMap(center:CLLocationCoordinate2D) {
        var tilesLoaded = false
        self.thematicLayer = RMMBTilesSource(tileSetURL: NSURL(fileURLWithPath: basemapPath()!, isDirectory: false))
        self.map = RMMapView(frame: view.bounds, andTilesource: self.thematicLayer)
        map.zoom = 13
        map.maxZoom = 15
        map.minZoom = 9
        map.centerCoordinate = center
        self.backgroundView.insertSubview(map, atIndex: 0)
        
        map.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        map.setConstraintsSouthWest(southWestConstraints, northEast: northEastConstraints)
        
        map.userTrackingMode = RMUserTrackingModeNone
        self.navigationItem.rightBarButtonItem = RMUserTrackingBarButtonItem(mapView: map)
    }
    
    
}