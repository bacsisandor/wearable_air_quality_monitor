//
//  Settings.swift
//  WearableAirQualityMonitor
//
//  Created by Bácsi Sándor on 2017. 12. 30..
//  Copyright © 2017. Bacsi Sandor. All rights reserved.
//
import BlueCapKit
import CoreBluetooth
import UIKit

class Settings: UIViewController {
  
  @IBOutlet weak var serviceUUID: UITextField!
  @IBOutlet weak var dataCharacteristicUUID: UITextField!
  
  @IBAction func connectButtonTouchUpInside(_ sender: Any) {
    view.endEditing(true)
    self.setupConnection()
  }
  
  @IBAction func settingsControlTouchUpInside(_ sender: Any) {
    view.endEditing(true)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  func setupConnection(){
    let serviceUUID = CBUUID(string:self.serviceUUID.text!)
    var peripheral: Peripheral?
    let dataCharacteristicUUID = CBUUID(string:self.dataCharacteristicUUID.text!)
    
    //initialize a central manager with a restore key. The restore key allows to resuse the same central manager in future calls
    let manager = CentralManager(options: [CBCentralManagerOptionRestoreIdentifierKey : "CentralMangerKey" as NSString])
    
    //A future stram that notifies us when the state of the central manager changes
    let stateChangeFuture = manager.whenStateChanges()
    
    //handle state changes and return a scan future if the bluetooth is powered on.
    let scanFuture = stateChangeFuture.flatMap { state -> FutureStream<Peripheral> in
      switch state {
      case .poweredOn:
        DispatchQueue.main.async {
          //print("start scanning");
        }
        //scan for peripherlas that advertise the ec00 service
        return manager.startScanning(forServiceUUIDs: [serviceUUID])
      case .poweredOff:
        throw AppError.poweredOff
      case .unauthorized, .unsupported:
        throw AppError.invalidState
      case .resetting:
        throw AppError.resetting
      case .unknown:
        //generally this state is ignored
        throw AppError.unknown
      }
    }
    
    scanFuture.onFailure { error in
      guard let appError = error as? AppError else {
        return
      }
      switch appError {
      case .invalidState:
        break
      case .resetting:
        manager.reset()
      case .poweredOff:
        break
      case .unknown:
        break
      default:
        break;
      }
    }
    
    //We will connect to the first scanned peripheral
    let connectionFuture = scanFuture.flatMap { p -> FutureStream<Void> in
      //stop the scan as soon as we find the first peripheral
      manager.stopScanning()
      peripheral = p
      guard let peripheral = peripheral else {
        throw AppError.unknown
      }
      DispatchQueue.main.async {
        print("Found peripheral \(peripheral.identifier.uuidString). Trying to connect")
      }
      //connect to the peripheral in order to trigger the connected mode
      return peripheral.connect(connectionTimeout: 10, capacity: 5)
    }
    
    //we will next discover the "ec00" service in order be able to access its characteristics
    let discoveryFuture = connectionFuture.flatMap { _ -> Future<Void> in
      guard let peripheral = peripheral else {
        throw AppError.unknown
      }
      return peripheral.discoverServices([serviceUUID])
      }.flatMap { _ -> Future<Void> in
        guard let discoveredPeripheral = peripheral else {
          throw AppError.unknown
        }
        guard let service = discoveredPeripheral.services(withUUID:serviceUUID)?.first else {
          throw AppError.serviceNotFound
        }
        peripheral = discoveredPeripheral
        DispatchQueue.main.async {
          print("Discovered service \(service.uuid.uuidString). Trying to discover characteristics")
        }
        //we have discovered the service, the next step is to discover the "ec0e" characteristic
        return service.discoverCharacteristics([dataCharacteristicUUID])
    }
    
    let dataFuture = discoveryFuture.flatMap { _ -> Future<Void> in
      guard let discoveredPeripheral = peripheral else {
        throw AppError.unknown
      }
      guard let dataCharacteristic = discoveredPeripheral.services(withUUID:serviceUUID)?.first?.characteristics(withUUID:dataCharacteristicUUID)?.first else {
        throw AppError.dataCharactertisticNotFound
      }
      
      BluetoothHelper.sharedInstance.dataCharacteristic=dataCharacteristic
      DispatchQueue.main.async {
        print("Discovered characteristic \(dataCharacteristic.uuid.uuidString).")
      }
      
      //read the data from the characteristic
      //Ask the characteristic to start notifying for value change
      return dataCharacteristic.startNotifying()
    }
    
    //handle any failure in the previous chain
    dataFuture.onFailure { error in
      switch error {
      case PeripheralError.disconnected:
        peripheral?.reconnect()
      case AppError.serviceNotFound:
        break
      case AppError.dataCharactertisticNotFound:
        break
      default:
        break
      }
    }
  }
}
