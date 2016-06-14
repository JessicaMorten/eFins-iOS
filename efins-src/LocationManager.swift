//
//  locationManager.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 5/20/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManagerDelegate : AnyObject {
    func locationManagerDidUpdateLocation(location: CLLocation)
    func locationManagerDidFailToObtainLocation()
}

struct DelegateRecord : Equatable {
    let accuracy : CLLocationAccuracy
    let timeout: NSDate
    let delegate: LocationManagerDelegate
    let eventDelivered: Bool
    
}
func ==(lhs: DelegateRecord, rhs: DelegateRecord) -> Bool {
    return lhs.delegate === rhs.delegate
}

func ===(lhs: DelegateRecord, rhs: DelegateRecord) -> Bool {
    return lhs.delegate === rhs.delegate
}

extension NSDate {
    func isAfter(dateToCompare: NSDate) -> Bool {
        return self.compare(dateToCompare) == NSComparisonResult.OrderedDescending
    }
    
    func isBefore(dateToCompare: NSDate) -> Bool {
        return self.compare(dateToCompare) == NSComparisonResult.OrderedAscending
    }
    
    func isBeforeNow() -> Bool {
        return self.isBefore(NSDate(timeIntervalSinceNow: 0))
    }
    
    func isAfterNow() -> Bool {
        return self.isAfter(NSDate(timeIntervalSinceNow: 0))
    }
    
    func areStandardSwiftDateComparisonsAnyGood() -> Bool { return false }
    
}



class LocationManager : NSObject, CLLocationManagerDelegate {
    var currentLocation = CLLocation()
    var currentLocationAccuracy = CLLocationAccuracy()
    let coreLocationManager = CLLocationManager()
    var observers: [DelegateRecord] = []
    var accuracyHistory: [CLLocationAccuracy] = []
    var timer : NSTimer? = nil
    var isPreheating = false
    var errorCount = 0
    static let sharedInstance = LocationManager()
    static let ACCURACY_BUFFER_LENGTH = 3
    static let MAX_LOCATION_ERROR = 3
    
    
    override init() {
        super.init()
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.Restricted || status == CLAuthorizationStatus.Denied {
            print("Raise an alert or something - location services not available")
        } else {
            coreLocationManager.delegate = self
        }
        
        if status == CLAuthorizationStatus.NotDetermined {
            coreLocationManager.requestWhenInUseAuthorization()
        }
    }
    
    func addLocationManagerDelegate(delegate: LocationManagerDelegate, accuracy: CLLocationAccuracy?, timeout: NSTimeInterval?) {
        print("Adding a delegate listener")
        var trueAccuracy : CLLocationAccuracy = -1
        var timeoutDatetime : NSDate
        if timeout == nil {
            timeoutDatetime = NSDate(timeIntervalSince1970: -1)
        } else {
            timeoutDatetime = NSDate(timeIntervalSinceNow: timeout!)
        }
        
        if accuracy != nil {
            trueAccuracy = accuracy!
        }
        
        let observer = DelegateRecord(accuracy: trueAccuracy, timeout: timeoutDatetime, delegate: delegate, eventDelivered: false)
        if !isObservingFor(delegate) {
            observers.append(observer)
        }
        if timer == nil {
            timer = NSTimer(timeInterval: 2, target: self, selector: "checkForTimeouts", userInfo: nil, repeats: true)
        } else {
            print("Attempted double add of delegate to location manager")
        }
        coreLocationManager.startUpdatingLocation()
        
    }
    
    func removeLocationManagerDelegate(delegate: LocationManagerDelegate) {
        print("Removing a delegate")
        print(observers.count)
        observers = observers.filter { if $0.delegate === delegate {return true } else {return false} }
        print(observers.count)
        if observers.count == 0 && (!isPreheating) {
            accuracyHistory.removeAll()
            coreLocationManager.stopUpdatingLocation()
        }
    }
    
    func startPreheat() {
        print("Start preheat")
        isPreheating = true
        coreLocationManager.startUpdatingLocation()
        
    }
    
    func stopPreheat() {
        print("Stop preheat")
        isPreheating = false
        if observers.count == 0 {
            coreLocationManager.stopUpdatingLocation()
        }
    }
    
    private func isObservingFor(delegate: LocationManagerDelegate) -> Bool {
        return observers.filter { $0.delegate === delegate }.count > 0
    }
    
    @objc private func checkForTimeouts() {
        for record in observers {
            record.delegate.locationManagerDidFailToObtainLocation()
            observers = observers.filter {$0 != record}
            stopTimerIfNecessary()
            if observers.count == 0 && (!isPreheating) {
                coreLocationManager.stopUpdatingLocation()
                accuracyHistory.removeAll()
            }
        }
    }
    
    private func stopTimerIfNecessary() {
        if observers.count == 0 {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func recordAccuracyMeasurement(accuracy : CLLocationAccuracy) {
        print("Record \(accuracy)")
        accuracyHistory.append(accuracy)
        if accuracyHistory.count > LocationManager.ACCURACY_BUFFER_LENGTH {
            accuracyHistory.removeAtIndex(0)
        }
    }
    
    private func accuracyHasConverged(minimumAccuracy: CLLocationAccuracy) -> Bool {
        if accuracyHistory.count < LocationManager.ACCURACY_BUFFER_LENGTH { return false }
        let initialAccuracy = accuracyHistory.first
        print("accuracyHasConverged: initial accuracy \(initialAccuracy)")
        if minimumAccuracy != -1 && initialAccuracy > minimumAccuracy {return false }
        for measurement in accuracyHistory {
            if measurement > initialAccuracy {return false}
        }
        print("Accuracy has converged at \(accuracyHistory) and \(minimumAccuracy) was requested.")
        return true
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var satisfiedObservers : [DelegateRecord] = []
        let mostRecentLocation : CLLocation = locations.last as CLLocation!
        recordAccuracyMeasurement(mostRecentLocation.horizontalAccuracy)
        print("Most recent location: \(mostRecentLocation). \(observers.count) observers")
        for observer in observers {
            let desiredAccuracy : CLLocationAccuracy = observer.accuracy
            if accuracyHasConverged(desiredAccuracy) {
                observer.delegate.locationManagerDidUpdateLocation(mostRecentLocation)
                satisfiedObservers.append(observer)
            }
        }
        observers = observers.filter {
            let o = $0
            if satisfiedObservers.filter({$0 == o}).count > 0 {return false}
            return true
        }
        stopTimerIfNecessary()
        if observers.count == 0 && (!isPreheating) {
            coreLocationManager.stopUpdatingLocation()
            accuracyHistory.removeAll()
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        errorCount += 1
        if errorCount >= LocationManager.MAX_LOCATION_ERROR {
            coreLocationManager.stopUpdatingLocation()
            accuracyHistory.removeAll()
            errorCount = 0
        }
    }
    
    
    
    
    
    
}
