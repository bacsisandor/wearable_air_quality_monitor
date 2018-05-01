//
//  AppError.swift
//  WearableAirQualityMonitor
//
//  Created by Bácsi Sándor on 2018. 01. 12..
//  Copyright © 2018. Bacsi Sandor. All rights reserved.
//

import Foundation

public enum AppError : Error {
  case dataCharactertisticNotFound
  case enabledCharactertisticNotFound
  case updateCharactertisticNotFound
  case serviceNotFound
  case invalidState
  case resetting
  case poweredOff
  case unknown
}
