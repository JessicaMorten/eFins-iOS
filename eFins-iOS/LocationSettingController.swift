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


class LocationSettingController : UITableViewController, RMMapViewDelegate {
    @IBOutlet weak var mapViewContainer: UIView!
    @IBOutlet weak var longitudeCell: UITableViewCell!
    @IBOutlet weak var latitudeCell: UITableViewCell!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    var location : CLLocation?
    var canEdit  = true
    var manuallyEntered = false
    var originalManuallyEntered = false
    var originalLatitude = Double(0)
    var originalLongitude = Double(0)
    let mapView = MapViewController(splitViewMode: false)
    var delegate : GeoPickerConsumer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        mapView.initMap()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        displayValues()
    }
    
    
    func setupWithLocation(location: CLLocation, wasManuallyEntered: Bool, withEditingAbility: Bool) {
        self.location = location
        originalLatitude = location.coordinate.latitude
        originalLongitude = location.coordinate.longitude
        originalManuallyEntered = wasManuallyEntered
        manuallyEntered = originalManuallyEntered
        
    }
    
    func registerListener(listener: GeoPickerConsumer, withImmediateCallback: Bool = false) {
        delegate = listener
        if withImmediateCallback {
            listener.didSetLocation(location!, wasManuallyEntered: manuallyEntered)
        }
        
    }
    
    func unregisterListener(listener: GeoPickerConsumer) {
        delegate = nil
    }
    
    private func displayValues() {
        let (latDeg, latMin) = CoordinateConverter.decimalDegrees2degreesMinutes(degrees: location!.coordinate.latitude)
        let (longDeg, longMin) = CoordinateConverter.decimalDegrees2degreesMinutes(degrees: location!.coordinate.longitude)
        let latText = String(format: "%3.0f\u{00b0} %.3f\u{2032}", latDeg, latMin)
        let longText = String(format: "%3.0f\u{00b0} %.3f\u{2032}", longDeg, longMin)
        latitudeCell.detailTextLabel?.text = latText
        longitudeCell.detailTextLabel?.text = longText
        zoomToLocation(location!, zoomLevel: mapView.map.zoom)
        drawLocation(location!, label: "location")
        if manuallyEntered {manualEntryHappened()}
    }
    
    private func drawLocation(location : CLLocation, label : String) {
        mapView.map.removeAllAnnotations()
        let annotation = RMPointAnnotation(mapView: mapView.map, coordinate: location.coordinate, andTitle: label)
        mapView.map.addAnnotation(annotation)
    }
    
    private func zoomToLocation(location: CLLocation, zoomLevel: Float) {
        mapView.map.setZoom(zoomLevel, animated: true)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !canEdit {
            return
        }
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        if indexPath.item == 0 {
            let delegate = LatPickerDelegate()
            delegate.toCall = latChanged
            let (latDeg, latMin, latSec) = CoordinateConverter.decimalDegrees2degreesMinutesSeconds(location!.coordinate.latitude)
            ActionSheetCustomPicker.showPickerWithTitle(nil, delegate: delegate, showCancelButton: true, origin: tableView, initialSelections: [latDeg, latMin, latSec])
        } else if indexPath.item == 1 {
            let delegate = LonPickerDelegate()
            delegate.toCall = lonChanged
            let (lonDeg, lonMin, lonSec) = CoordinateConverter.decimalDegrees2degreesMinutesSeconds(location!.coordinate.latitude)
            ActionSheetCustomPicker.showPickerWithTitle(nil, delegate: delegate, showCancelButton: true, origin: tableView, initialSelections: [lonDeg, lonMin, lonSec])
            
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    private func manualEntryHappened() {
        manuallyEntered = true
        cancelButton.action = "resetToOriginalLocation"
        navigationItem.setRightBarButtonItem(cancelButton, animated: true)
    }
    
    private func latChanged(lat : Double) {
        location = CLLocation(latitude: lat, longitude: location!.coordinate.longitude)
    }
    
    private func lonChanged(lon : Double) {
        location = CLLocation(latitude: location!.coordinate.latitude, longitude: lon)
    }
    
    private func singleTapOnMap(map: RMMapView!, at point: CGPoint) {
        if !canEdit { return }
        let tappedOn = map.pixelToCoordinate(point)
        location = CLLocation(latitude: tappedOn.latitude, longitude: tappedOn.longitude)
        manualEntryHappened()
        displayValues()
        delegate?.didSetLocation(location!, wasManuallyEntered: true)
    }
    
    private func resetToOriginalLocation()  {
        location = CLLocation(latitude: originalLatitude, longitude: originalLongitude)
        manuallyEntered = originalManuallyEntered
        navigationItem.setRightBarButtonItem(nil, animated: true)
        displayValues()
        delegate?.didSetLocation(location!, wasManuallyEntered: manuallyEntered)
    }

}

protocol GeoPickerConsumer {
    func didSetLocation(location: CLLocation, wasManuallyEntered: Bool)
}

class LatPickerDelegate : NSObject, ActionSheetCustomPickerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    var toCall : ((coordinate : Double) -> ())? = nil

    
    func configurePickerView(pickerView: UIPickerView) {
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {return 179 }
        else if component == 1 {return 60}
        else if component == 2 {return 100}
        else {return 0}
    }
    
    func pickerView(pickerView: UIPickerView, row: Int, component: Int, view: UIView!) -> UIView {
        var label = view as? UILabel
        if  label == nil {
            label = UILabel(frame: CGRectMake(0.0, 0.0, pickerView.rowSizeForComponent(component).width - 10.0, pickerView.rowSizeForComponent(component).height))
        }
        if component == 0 {
            label!.text = String(format: "%ld \u{00b0}", row - 89)
            label!.textAlignment = NSTextAlignment.Right
        } else if component == 1 {
            label!.text = String(format:"%ld.", row)
            label!.textAlignment = NSTextAlignment.Right
        } else if component == 2 {
            label!.text = String(format: "%02ld \u{2032}", row)
            label!.textAlignment = NSTextAlignment.Left
        }
        return label!
    }
    
    @objc func actionSheetPickerDidSucceed(actionSheetPicker: AbstractActionSheetPicker!, origin: AnyObject!) {
        let picker = actionSheetPicker as! ActionSheetCustomPicker
        let pick : UIPickerView = picker.pickerView as! UIPickerView
        let latDeg = CLLocationDegrees(pick.selectedRowInComponent(0) - 89)
        let minutes = Double(pick.selectedRowInComponent(1))
        let seconds = Double(pick.selectedRowInComponent(2))
        let lat = CoordinateConverter.degreesMinutesSeconds2DecimalDegrees(degrees: latDeg, minutes: minutes, seconds: seconds)
        toCall!(coordinate: lat)
        
    }
    
}

class LonPickerDelegate : NSObject, ActionSheetCustomPickerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    var toCall : ((coordinate : Double) -> ())? = nil

    
    
    func configurePickerView(pickerView: UIPickerView) {
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {return 359 }
        else if component == 1 {return 60}
        else if component == 2 {return 100}
        else {return 0}
    }
    
    func pickerView(pickerView: UIPickerView, row: Int, component: Int, view: UIView!) -> UIView {
        var label = view as? UILabel
        if  label == nil {
            label = UILabel(frame: CGRectMake(0.0, 0.0, pickerView.rowSizeForComponent(component).width - 10.0, pickerView.rowSizeForComponent(component).height))
        }
        if component == 0 {
            label!.text = String(format: "%ld \u{00b0}", row - 179)
            label!.textAlignment = NSTextAlignment.Right
        } else if component == 1 {
            label!.text = String(format:"%ld.", row)
            label!.textAlignment = NSTextAlignment.Right
        } else if component == 2 {
            label!.text = String(format: "%02ld \u{2032}", row)
            label!.textAlignment = NSTextAlignment.Left
        }
        return label!
    }
    
    @objc func actionSheetPickerDidSucceed(actionSheetPicker: AbstractActionSheetPicker!, origin: AnyObject!) {
        let picker = actionSheetPicker as! ActionSheetCustomPicker
        let pick : UIPickerView = picker.pickerView as! UIPickerView
        let lonDeg = CLLocationDegrees( pick.selectedRowInComponent(0) - 179 )
        let minutes = Double(pick.selectedRowInComponent(1))
        let seconds = Double(pick.selectedRowInComponent(2))
        let long = CoordinateConverter.degreesMinutesSeconds2DecimalDegrees(degrees: lonDeg, minutes: minutes, seconds: seconds)
        toCall!(coordinate: long)
    }
    
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
        let degreesOnly = Double(Int(degrees))
        let minutesOnly = (degreesOnly - degrees) * 60.0
        return (degreesOnly, minutesOnly)
        
    }
    
    class func decimalDegrees2degreesMinutesSeconds(degrees: CLLocationDegrees) -> (degrees : Double, minutes: Double, seconds: Double) {
        let (deg, min) = decimalDegrees2degreesMinutes(degrees: degrees)
        let minutes = Double(Int(min))
        let seconds = min - minutes
        return (degrees, minutes, seconds)
    }
    
}


