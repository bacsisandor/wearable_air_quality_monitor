//
//  History.swift
//  WearableAirQualityMonitor
//
//  Created by Bácsi Sándor on 2017. 12. 30..
//  Copyright © 2017. Bacsi Sandor. All rights reserved.
//

import CoreData
import UIKit

class History: UITableViewController {
  private var fetchedResultsController: NSFetchedResultsController<MeasuredValue>!
  
  override func viewDidLoad() {
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
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let sectionInfo = fetchedResultsController.sections?[section] else {
      return 0
    }
    return sectionInfo.numberOfObjects
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "MeasuredValueCell", for: indexPath)
    configure(cell: cell, at: indexPath)
    return cell
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let managedObjectContext = AppDelegate.managedContext
      let measuredValueToDelete = fetchedResultsController.object(at: indexPath)
      managedObjectContext.delete(measuredValueToDelete)
    }
  }
  
  func configure(cell: UITableViewCell, at indexPath: IndexPath) {
    let measuredValue = fetchedResultsController.object(at: indexPath)
    var measuredTemperature = measuredValue.temperature!
    measuredTemperature.removeLast()
    var measuredHumidity = measuredValue.humidity!
    measuredHumidity.removeLast()
    var measuredDustDensity = measuredValue.dustDensity!
    measuredDustDensity.removeLast()
    cell.textLabel?.text = measuredTemperature + "°C\n" + measuredHumidity + "%\n" + measuredDustDensity + "ug/m3"
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .short
    cell.detailTextLabel?.text = dateFormatter.string(from: measuredValue.creationDate!)
  }
}
  
extension History: NSFetchedResultsControllerDelegate {
  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.beginUpdates()
  }
  
  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    switch type {
    case .insert:
      tableView.insertRows(at: [newIndexPath!], with: .fade)
    case .delete:
      tableView.deleteRows(at: [indexPath!], with: .automatic)
    default:
      break
    }
  }
  
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.endUpdates()
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
}
