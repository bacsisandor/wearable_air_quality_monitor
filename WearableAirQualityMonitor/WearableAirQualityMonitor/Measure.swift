//
//  Measure.swift
//  WearableAirQualityMonitor
//
//  Created by Bácsi Sándor on 2017. 12. 30..
//  Copyright © 2017. Bacsi Sandor. All rights reserved.
//

import CoreData
import CoreLocation
import Firebase
import Foundation
import LTMorphingLabel
import UICircularProgressRing
import UIKit

class Measure: UIViewController {
  
  @IBOutlet weak var humidityProgressRing: UICircularProgressRingView!
  @IBOutlet weak var measureView: UIView!

  @IBOutlet weak var dustDensityLabel: UILabel!
  @IBOutlet weak var temperatureLabel: LTMorphingLabel!
  let rootRef = Database.database().reference()
  
  var location: CLLocation?
  private var locationManager = LocationManager()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    humidityProgressRing.font = UIFont.systemFont(ofSize: 40)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    locationManager.startLocationManager { [weak self] in
      if let location = self?.locationManager.lastLocation {
        self?.location = location
      }
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    locationManager.stopLocationManager()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    humidityProgressRing.setProgress(value: 0, animationDuration: 0)
    temperatureLabel.text=""
    dustDensityLabel.text=""
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    humidityProgressRing.setProgress(value: 0, animationDuration: 0)
    temperatureLabel.text=""
    dustDensityLabel.text=""
  }
  
  @IBAction func shareButtonTouchUpInside(_ sender: Any) {
    let image =  UIImage.init(view: measureView)
    let imageToShare = [image]
    let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
    activityViewController.popoverPresentationController?.sourceView = self.view
    self.present(activityViewController, animated: true, completion: nil)
  }
  
  //http://www.levegominoseg.hu/Media/Default/Ertekeles/docs/2015_pm10_pah_ertekles.pdf
  func calculatePollutionIndex(dustDensity: String) -> String {
    let dustDensityValue = Double(dustDensity)
    if (dustDensityValue! < 10.0){
      return "Excellent Air Quality"
    }
    else if (dustDensityValue! >= 10.0  && dustDensityValue! < 20.0 ) {
      return "Good Air Quality"
    }
    else if (dustDensityValue! >= 20.0  && dustDensityValue! < 25.0 ) {
      return "Adequate Air Quality"
    }
    else if (dustDensityValue! >= 25.0  && dustDensityValue! < 50.0 ) {
      return "Polluted Air"
    }
    else {
      return "Extremely Polluted Air"
    }
  }
  
  
  @IBAction func measureButtonTouchUpInside(_ sender: Any) {
    humidityProgressRing.setProgress(value: 0, animationDuration: 0)
    temperatureLabel.text=""
    let readFuture = BluetoothHelper.sharedInstance.dataCharacteristic?.read(timeout: 5)
    
    readFuture?.onSuccess { (_) in
      let s = String(data:(BluetoothHelper.sharedInstance.dataCharacteristic?.dataValue)!, encoding: .utf8)
      var values = s?.components(separatedBy: "_")
      if values?.count==3 {
        let humidity = values![0]
        let temperature = values![1]
        let dustDensity = values![2]
        
        //Save values to CoreData
        let managedObjectContext = AppDelegate.managedContext
        let measuredValue = MeasuredValue(context: managedObjectContext)
        measuredValue.creationDate = Date()
        measuredValue.humidity = humidity
        measuredValue.temperature = temperature
        measuredValue.dustDensity = dustDensity
        measuredValue.latitude = (self.location?.coordinate.latitude)!
        measuredValue.longitude = (self.location?.coordinate.longitude)!
        
        //Upload values to FireBase realtime database
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: measuredValue.creationDate!)
        let month = calendar.component(.month, from: measuredValue.creationDate!)
        let day = calendar.component(.day, from: measuredValue.creationDate!)
        let hour = calendar.component(.hour, from: measuredValue.creationDate!)
        let minutes = calendar.component(.minute, from: measuredValue.creationDate!)
        let seconds = calendar.component(.second, from: measuredValue.creationDate!)
        
        let keyID = UIDevice.current.identifierForVendor!.uuidString + "-" + String(year) + "-" + String(month) + "-" + String(day) + "-" + String(hour) + "-" + String(minutes) + "-" + String(seconds)
        let clientRef = self.rootRef.child(keyID)
        
        let temperatureRef = clientRef.child("Temperature")
        temperatureRef.setValue(measuredValue.temperature)
        
        let humidityRef = clientRef.child("Humidity")
        humidityRef.setValue(measuredValue.humidity)
        
        let dustDensityRef = clientRef.child("DustDensity")
        dustDensityRef.setValue(measuredValue.dustDensity)
        
        let latitudeRef = clientRef.child("Latitude")
        latitudeRef.setValue(measuredValue.latitude)
        
        let longitudeRef = clientRef.child("Longitude")
        longitudeRef.setValue(measuredValue.longitude)
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        //Delete previous values
        values?.removeAll()
        
        DispatchQueue.main.async {
          let valueHumidity = CGFloat((humidity as NSString).floatValue)
          self.humidityProgressRing.setProgress(value: valueHumidity, animationDuration: 2)
          let effect = LTMorphingEffect(rawValue:4)
          self.temperatureLabel.morphingEffect=effect!
          let choppedStringTemperature = String(temperature.dropLast())
          self.temperatureLabel.text = choppedStringTemperature + "°"
          self.dustDensityLabel.text = self.calculatePollutionIndex(dustDensity: dustDensity)
        }
      }
    }
    readFuture?.onFailure { (_) in
      print("read error")
    }
  }
}

extension UIImage{
  convenience init(view: UIView) {
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.isOpaque, 0.0)
    view.drawHierarchy(in: view.bounds, afterScreenUpdates: false)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    self.init(cgImage: (image?.cgImage)!)
  }
}
