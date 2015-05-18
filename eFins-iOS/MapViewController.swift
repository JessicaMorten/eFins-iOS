//
//  MapViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/18/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit

class MapViewController: UIViewController {
    
    var map:RMMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        RMConfiguration.sharedInstance().accessToken = "pk.eyJ1IjoianVzdGluIiwiYSI6IlpDbUJLSUEifQ.4mG8vhelFMju6HpIY-Hi5A"
        let source = RMMapboxSource(mapID: "examples.map-z2effxa8")
        self.map = RMMapView(frame: view.bounds, andTilesource: source)
        map.zoom = 9
        map.centerCoordinate = CLLocationCoordinate2D(latitude: 34.007, longitude: -119.829)
        
        view.insertSubview(map, atIndex: 0)
        self.splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden
        map.userTrackingMode = RMUserTrackingModeNone
        self.navigationItem.rightBarButtonItem = RMUserTrackingBarButtonItem(mapView: map)
        map.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        let southWest = CLLocationCoordinate2DMake(31.617, -123.02)
        let northEast = CLLocationCoordinate2DMake(35.42, -114.58)
        map.setConstraintsSouthWest(southWest, northEast: northEast)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
