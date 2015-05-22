//
//  locationManager.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 5/20/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationManagerDelegate {
    func locationManagerDidUpdateLocation(location: CLLocation)
    func locationManagerDidFailToObtainLocation(location: CLLocation)
}


class LocationManager : CLLocationManagerDelegate {
    var currentLocation = CLLocation()
    var currentLocationAccuracy = CLLocationAccuracy()
    let coreLocationManager = CLLocationManager()
    var observers: [DelegateRecord]
    var accuracyHistory: [CLLocationAccuracy] = []
    var timer : NSTimer? = nil
    var isPreheating = false
    static let sharedInstance = LocationManager()
    static let ACCURACY_BUFFER_LENGTH = 3
    static let MAX_LOCATION_ERROR = 10
    
    struct DelegateRecord {
        let accuracy : CLLocationAccuracy
        let timeout: NSDate
        let delegate: LocationManagerDelegate
        let eventDelivered: Bool
    }
    
    init() {
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.Restricted || status == CLAuthorizationStatus.Denied {
            println("Raise an alert or something - location services not available")
        } else {
            coreLocationManager.delegate = self
        }
        
        if status == CLAuthorizationStatus.NotDetermined {
            coreLocationManager.requestWhenInUseAuthorization()
        }
    }
    
    func addLocationManagerDelegate(delegate: LocationManagerDelegate, accuracy: CLLocationAccuracy?, timeout: NSTimeInterval?) {
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
            println("Attempted double add of delegate to location manager")
        }
        coreLocationManager.startUpdatingLocation()
        
    }
    
    func removeLocationManagerDelegate(delegate: LocationManagerDelegate) {
        observers = observers.filter { if $0.delegate === delegate {return true } else {return false} }
        if count(observers) == 0 && (!isPreheating) {
            accuracyHistory.removeAll()
            coreLocationManager.stopUpdatingLocation()
        }
    }
    
    func startPreheat() {
        isPreheating = true
        coreLocationManager.startUpdatingLocation()
        
    }
    
    func stopPreheat() {
        isPreheating = false
        if count(observers) == 0 {
            coreLocationManager.stopUpdatingLocation()
        }
    }
    
    private func observersWithTimeouts() -> [DelegateRecord] {
        return observers.filter {$0.timeout > NSDate(timeIntervalSince1970: -1)}
    }
    
    private func isObservingFor(delegate: LocationManagerDelegate) -> Bool {
        return observers.filter { $0.delegate === delegate }.count > 0
    }
    
    @objc private func checkForTimeouts() {
        var delegatesToTimeout = []
        for record in observersWithTimeouts() {
            let timeoutDate : NSDate = record.timeout
            if timeoutDate.timeIntervalSinceReferenceDate < NSDate(timeIntervalSinceNow: 0) {
                delegatesToTimeout.add(record)
            }
        }
        
        for record in delegatesToTimeout {
            record.delegate.locationManagerDidFailtoObtainLocation()
            observers = observers.filter {$0.delegate != record.delegate}
            stopTimerIfNecessary()
            if count(observers) == 0 && (!isPreheating) {
                coreLocationManager.stopUpdatingLocation()
                accuracyHistory.removeAll()
            }
        }
        
    }
    
    private func stopTimerIfNecessary() {
        if count(observersWithTimeouts()) == 0 {
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func recordAccuracyMeasurement(accuracy : CLLocationAccuracy) {
        accuracyHistory.append(accuracy)
        if count(accuracyHistory) > LocationManager.ACCURACY_BUFFER_LENGTH {
            accuracyHistory.removeAtIndex(0)
        }
    }
    
    private func accuracyHasConverged(minimumAccuracy: CLLocationAccuracy) -> Bool {
        if count(accuracyHistory) < LocationManager.ACCURACY_BUFFER_LENGTH { return false }
        let initialAccuracy = accuracyHistory.first
        println("accuracyHasConverged: initial accuracy \(initialAccuracy)")
        if minimumAccuracy != -1 && initialAccuracy > minimumAccuracy {return false }
        for measurement in accuracyHistory {
            if measurement > initialAccuracy {return false}
        }
        println("Accuracy has converged at \(accuracyHistory) and \(minimumAccuracy) was requested.")
        return true
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var satisfiedObservers : [Dictionary] = []
        let mostRecentLocation : CLLocation = locations.last
        recordAccuracyMeasurement(mostRecentLocation.horizontalAccuracy)
    }
    
    
    
    
    
    
}
