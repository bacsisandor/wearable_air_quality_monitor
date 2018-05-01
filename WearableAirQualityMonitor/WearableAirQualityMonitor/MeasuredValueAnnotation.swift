//
//  MeasuredValueAnnotation.swift
//  WearableAirQualityMonitor
//
//  Created by Bácsi Sándor on 2018. 01. 15..
//  Copyright © 2018. Bacsi Sandor. All rights reserved.
//

import MapKit

class MeasuredValueAnnotation: NSObject {
  
  var coordinate: CLLocationCoordinate2D
  var title: String?
  var subtitle: String?
  
  init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
    self.coordinate = coordinate
    self.title = title
    self.subtitle = subtitle
  }
}

extension MeasuredValueAnnotation: MKAnnotation {}

