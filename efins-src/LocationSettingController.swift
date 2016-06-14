//
//  LocationSetting.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 5/25/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import UIKit
import ActionSheetPicker_3_0
import MapKit


@objc class LocationSettingController : UITableViewController, MKMapViewDelegate {
    @IBOutlet weak var mapViewContainer: UIView! // This is the table view cell the map lives in
    @IBOutlet weak var longitudeCell: UITableViewCell!
    @IBOutlet weak var latitudeCell: UITableViewCell!
    @IBOutlet weak var mapCell: UITableViewCell!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    var location : CLLocationCoordinate2D!
    var canEdit  = true
    var manuallyEntered = false
    var originalManuallyEntered = false
    var originalLatitude = Double(0)
    var originalLongitude = Double(0)
    var delegate : GeoPickerConsumer? = nil
    var map:MKMapView!
    //var thematicLayer:RMMBTilesSource?
    let southWestConstraints = CLLocationCoordinate2DMake(32, -123)
    let northEastConstraints = CLLocationCoordinate2DMake(35.42, -116.5)

    
    // This is the content view embedded in the table view cell for the map
    @IBOutlet var mapBackgroundView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.originalLatitude = self.location.latitude
        self.originalLongitude = self.location.longitude
        self.originalManuallyEntered = self.manuallyEntered
        self.tableView.delegate = self
        let uri = NSURL(string: SERVER_ROOT)
        let host = uri?.host ?? ""
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.initMap(CLLocationCoordinate2D(latitude: 34.007, longitude: -119.829))
        self.map.delegate = self
        displayValues()
    }
    
    
    func setupWithLocation(location: CLLocation, wasManuallyEntered: Bool, withEditingAbility: Bool) {
        self.location = location.coordinate
        print("\(location.coordinate.latitude), \(location.coordinate.longitude)")
        originalLatitude = location.coordinate.latitude
        originalLongitude = location.coordinate.longitude
        originalManuallyEntered = wasManuallyEntered
        manuallyEntered = originalManuallyEntered
        canEdit = withEditingAbility
    }
    
    func registerListener(listener: GeoPickerConsumer, withImmediateCallback: Bool = false) {
        delegate = listener
        if withImmediateCallback {
            let newLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            listener.didSetLocation(newLocation, wasManuallyEntered: manuallyEntered)
        }
        
    }
    
    func unregisterListener(listener: GeoPickerConsumer) {
        delegate = nil
    }
    
    func initMap(center:CLLocationCoordinate2D) {
        var tilesLoaded = false
        self.map = MKMapView(frame: self.mapCell.contentView.frame)
        setZoomLevel(9)
        //map.maxZoom = 15
        //map.minZoom = 8
        map.centerCoordinate = center
        self.mapCell.contentView.insertSubview(map, atIndex: 0)
        
        map.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
        //map.setConstraintsSouthWest(southWestConstraints, northEast: northEastConstraints)
        map.userTrackingMode = MKUserTrackingMode.None
        map.userInteractionEnabled = true
        //self.navigationItem.rightBarButtonItem = RMUserTrackingBarButtonItem(mapView: map)
    }

    
    private func displayValues() {
        let (latDeg, latMin) = CoordinateConverter.decimalDegrees2degreesMinutes(location!.latitude)
        let (longDeg, longMin) = CoordinateConverter.decimalDegrees2degreesMinutes(location!.longitude)
        let latText = String(format: "%3.0f\u{00b0} %.3f\u{2032}", latDeg, latMin)
        let longText = String(format: "%3.0f\u{00b0} %.3f\u{2032}", longDeg, longMin)
        latitudeCell.detailTextLabel?.text = latText
        longitudeCell.detailTextLabel?.text = longText
        drawLocation(location, label: "location")
        map.setCenterCoordinate(location, animated: true)
        if manuallyEntered {manualEntryHappened()}
    }
    
    private func drawLocation(location : CLLocationCoordinate2D, label : String) {
        self.map.removeAnnotations(self.map.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = label
        //let annotation = MKPointAnnotation(mapView: self.map, coordinate: location, andTitle: label)
        self.map.addAnnotation(annotation)
        self.map.selectAnnotation(annotation, animated: true)
    }
    
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.item == 2 {
            return tableView.frame.size.height - 64
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !canEdit {
            return
        }
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if indexPath.item == 0 {
            let delegate = LatPickerDelegate()
            delegate.receiver = self
            delegate.selectorToPerform = "latChanged:"
            let (latDeg, latMin, latSec) = CoordinateConverter.decimalDegrees2degreesMinutesSeconds(location.latitude)
            ActionSheetCustomPicker.showPickerWithTitle(nil, delegate: delegate, showCancelButton: true, origin: latitudeCell, initialSelections: [latDeg + 89, latMin, latSec * 100])
        } else if indexPath.item == 1 {
            let delegate = LonPickerDelegate()
            delegate.receiver = self
            delegate.selectorToPerform = "lonChanged:"
            let (lonDeg, lonMin, lonSec) = CoordinateConverter.decimalDegrees2degreesMinutesSeconds(location.longitude)
            //print(lonDeg, lonMin, lonSec)
            ActionSheetCustomPicker.showPickerWithTitle(nil, delegate: delegate, showCancelButton: true, origin: longitudeCell, initialSelections: [lonDeg + 179, lonMin, lonSec * 100])
            
        }
        return tableView.deselectRowAtIndexPath(indexPath, animated: true)

    }
    
    private func manualEntryHappened() {
        manuallyEntered = true
        cancelButton.action = "resetToOriginalLocation"
        cancelButton.target = self
        cancelButton.title = "Reset to Original Location"
        navigationItem.setRightBarButtonItem(cancelButton, animated: true)
    }
    
    @objc func latChanged(lat : NSNumber) {
        location = CLLocationCoordinate2D(latitude: lat.doubleValue, longitude: location.longitude)
        displayValues()
        manualEntryHappened()
    }
    
    @objc func lonChanged(lon : NSNumber) {
        location = CLLocationCoordinate2D(latitude: location.latitude, longitude: lon.doubleValue)
        displayValues()
        manualEntryHappened()
    }
    
    func updateLocation(newLocation : CLLocationCoordinate2D) {
        location = newLocation
        delegate?.didSetLocation(CLLocation(latitude: location.latitude, longitude: location.longitude), wasManuallyEntered: false)
        displayValues()
    }
    
    func singleTapOnMap(map: MKMapView!, at point: CGPoint) {
        //print("Tappity tap")
        if !canEdit { return }
        let tappedOn = map.convertPoint(point, toCoordinateFromView: map)
        //let tappedOn = map.pixelToCoordinate(point)
        location = CLLocationCoordinate2D(latitude: tappedOn.latitude, longitude: tappedOn.longitude)
        manualEntryHappened()
        displayValues()
        let newLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        delegate?.didSetLocation(newLocation, wasManuallyEntered: true)
    }
    
    func resetToOriginalLocation()  {
        location = CLLocationCoordinate2D(latitude: originalLatitude, longitude: originalLongitude)
        manuallyEntered = originalManuallyEntered
        navigationItem.setRightBarButtonItem(nil, animated: true)
        let newLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        delegate?.didSetLocation(newLocation, wasManuallyEntered: manuallyEntered)
        displayValues()
    }
    
    func setZoomLevel(zoomLevel : Double) {
        setCenterCoordinate(map.centerCoordinate, zoomLevel: zoomLevel, animated: true)
    }
    
    func zoomLevel() -> Int {
        return Int(log2(360 * (Double(map.frame.size.width/256) / map.region.span.longitudeDelta))) + 1
    }
    
    func setCenterCoordinate(centerCoordinate: CLLocationCoordinate2D, zoomLevel: Double, animated: Bool) {
        let span = MKCoordinateSpanMake(0, 360/pow(2, Double(zoomLevel))*Double(map.frame.size.width/256))
        map.setRegion(MKCoordinateRegionMake(centerCoordinate, span), animated: animated)
    }

}

protocol GeoPickerConsumer {
    func didSetLocation(location: CLLocation, wasManuallyEntered: Bool)
}


class CoordinateConverter {
    class func degreesMinutesSeconds2DecimalDegrees(degrees : CLLocationDegrees = 0.0, minutes: Double = 0.0, seconds: Double = 0.0) -> CLLocationDegrees {
        var degreesSign : Double = 1.0
        if degrees < 0 { degreesSign = -1.0 }
        var retDegrees : CLLocationDegrees = degrees
        retDegrees += degreesSign * (minutes / 60.0)
        retDegrees += degreesSign * (seconds / 3600.0)
        return retDegrees
    }
    
    class func decimalDegrees2degreesMinutes(degrees : CLLocationDegrees = 0.0) -> (degrees: Double, minutes : Double){
        var degreesSign : Double = 1.0
        if degrees < 0 { degreesSign = -1.0 }
        let posDegrees = abs(degrees)
        var degreesOnly = Double(Int(posDegrees))
        let minutesOnly = (posDegrees - degreesOnly) * 60.0
        degreesOnly = degreesOnly * degreesSign
        return (degreesOnly, minutesOnly)
        
    }
    
    class func decimalDegrees2degreesMinutesSeconds(degrees: CLLocationDegrees) -> (degrees : Double, minutes: Double, seconds: Double) {
        let (deg, min) = decimalDegrees2degreesMinutes(degrees)
        let minutes = Double(Int(min))
        let seconds = min - minutes
        return (deg, minutes, seconds)
    }
    
}


