//
//  LocationManager.swift
//  WearableAirQualityMonitor
//
//  Created by Bácsi Sándor on 2018. 01. 14..
//  Copyright © 2018. Bacsi Sandor. All rights reserved.
//

import CoreLocation
import Foundation

class LocationManager: NSObject {
  
  var lastLocation: CLLocation?
  private var timeoutTimer: Timer?
  private var locationUpdated: (() -> Void)!
  private var locationManager: CLLocationManager!
  
  //Get position
  func startLocationManager(updated: @escaping () -> Void) {
    
    locationUpdated = updated
    locationManager = CLLocationManager()
    locationManager.requestWhenInUseAuthorization()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    timeoutTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(LocationManager.stopLocationManager), userInfo: nil, repeats: false)
    locationManager.startUpdatingLocation()
  }
  
  //When timer stops
  @objc func stopLocationManager() {
    if let timer = timeoutTimer {
      timer.invalidate()
    }
    locationManager.stopUpdatingLocation()
    locationUpdated()
  }
}

extension LocationManager: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let newLocation = locations.last else {
      return
    }
    
    if -newLocation.timestamp.timeIntervalSinceNow > 5.0 {
      return
    }
    
    if newLocation.horizontalAccuracy < 0 {
      return
    }
    
    if lastLocation == nil || lastLocation!.horizontalAccuracy > newLocation.horizontalAccuracy {
      lastLocation = newLocation
      
      if newLocation.horizontalAccuracy <= manager.desiredAccuracy {
        stopLocationManager()
      }
    }
  }
  
  //In case of error
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    stopLocationManager()
    print(error.localizedDescription)
  }
}


