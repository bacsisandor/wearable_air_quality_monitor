//
//  BluetoothHelper.swift
//  WearableAirQualityMonitor
//
//  Created by Bácsi Sándor on 2018. 01. 12..
//  Copyright © 2018. Bacsi Sandor. All rights reserved.
//

import BlueCapKit
import Foundation

//Singleton pattern
class BluetoothHelper {
  static var sharedInstance = BluetoothHelper()
  private init() {}
  
  var dataCharacteristic : Characteristic?
}
