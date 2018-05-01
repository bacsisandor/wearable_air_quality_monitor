//
//  Map.swift
//  WearableAirQualityMonitor
//
//  Created by Bácsi Sándor on 2017. 12. 30..
//  Copyright © 2017. Bacsi Sandor. All rights reserved.
//

import CoreData
import MapKit
import UIKit

class Map: UIViewController {
  private var fetchedResultsController: NSFetchedResultsController<MeasuredValue>!
  
  @IBOutlet weak var mapView: MKMapView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let managedObjectContext = AppDelegate.managedContext
    let fetchRequest: NSFetchRequest<MeasuredValue> = MeasuredValue.fetchRequest()
    let sortDescriptor = NSSortDescriptor(key: #keyPath(MeasuredValue.creationDate), ascending: false)
    fetchRequest.sortDescriptors = [sortDescriptor]
    
    fetchRequest.fetchBatchSize = 30
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                          managedObjectContext: managedObjectContext,
                                                          sectionNameKeyPath: nil,
                                                          cacheName: nil)
    fetchedResultsController.delegate = self
    do {
      try fetchedResultsController.performFetch()
    } catch let error as NSError {
      print("\(error.userInfo)")
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }
  
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    for measuredValue in fetchedResultsController.fetchedObjects! {
      let coordinate = CLLocationCoordinate2D(latitude: measuredValue.latitude, longitude: measuredValue.longitude)
      var measuredTemperature = measuredValue.temperature!
      measuredTemperature.removeLast()
      var measuredHumidity = measuredValue.humidity!
      measuredHumidity.removeLast()
      var measuredDustDensity = measuredValue.dustDensity!
      measuredDustDensity.removeLast()

      
      let title = measuredTemperature + "°C\n" + measuredHumidity + "%\n" + measuredDustDensity  + "ug/m3"
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .medium
      dateFormatter.timeStyle = .short
      let subtitle = dateFormatter.string(from: measuredValue.creationDate!)
      let annotation = MeasuredValueAnnotation(coordinate: coordinate, title: title, subtitle: subtitle)
      self.mapView.addAnnotation(annotation)
    }
   }
  
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    mapView.annotations.forEach { annotation in
      self.mapView.removeAnnotation(annotation)
    }
  }
}

extension Map: NSFetchedResultsControllerDelegate {
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
     //Update
  }
  
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
     //Update
  }
}

