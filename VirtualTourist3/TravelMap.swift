//
//  TravelMap.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelMap: UIViewController, MKMapViewDelegate {
  
  /** Mark: - Outlets **/
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var editButton: UIBarButtonItem!
  @IBOutlet weak var deletePinLabel: UILabel!
  @IBOutlet var longPress: UILongPressGestureRecognizer!
  
  /** Mark: - Properties **/
  var fileName = "MapRegion"
  var filePath : String {
    let manager = NSFileManager.defaultManager()
    let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
    return url.URLByAppendingPathComponent(fileName).path!
  }
  
  /** Mark: - Core Data Context **/
  
  var sharedContext: NSManagedObjectContext{
    return CoreDataStackManager.sharedInstance().managedObjectContext!
  }
  
  /** Mark: - App Life Cycle **/
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // set map delegate and restore last seen region
    mapView.delegate = self
    restoreMapRegion(false)
    mapView.addAnnotations(fetchAllPins())
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  /** Mark: - Get All Pins **/
  
  func fetchAllPins() -> [Pin] {
    let error: NSErrorPointer = nil
    let fetchRequest = NSFetchRequest(entityName: "Pin")
    let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
    
    return results as! [Pin]
  }
  
  /** Mark: - Drop a Pin **/
  
  var pinToBeAdded: Pin? = nil
  
  @IBAction func tapHoldOnMap(gesturerecognizer: UILongPressGestureRecognizer) {
    var touchPoint = gesturerecognizer.locationInView(self.mapView)
    var newCoord: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
    
    switch gesturerecognizer.state{
    case .Ended:
      let dictionary: [String: AnyObject] = [
        Pin.Keys.Latitude: newCoord.latitude,
        Pin.Keys.Longitude: newCoord.longitude
      ]
      //create a Pin object with coordinates from touch point
      pinToBeAdded = Pin(dictionary: dictionary, context: sharedContext)
      FlickrClient.sharedInstance().getPhotosForPin(pinToBeAdded!, completionHandler: {
        success, error in
        if success{
          dispatch_async(dispatch_get_main_queue()){
            CoreDataStackManager.sharedInstance().saveContext()
          }
        }
      })
      //save it to core data
      CoreDataStackManager.sharedInstance().saveContext()
      //add it to the map
      mapView.addAnnotation(pinToBeAdded)
    default:
      return
    }
  }
  
  /** Mark: - Pin(s) Edit **/
  
  @IBAction func editButtonTapped(sender: UIBarButtonItem) {
    
    if editButton.title == "Edit Pins" {
      deletePinLabel.hidden = false
      editButton.title = "Done"
    }
    else if editButton.title == "Done" {
      deletePinLabel.hidden = true
      editButton.title = "Edit Pins"
    }
  }
  
  /** Mark: - Helper functions for map region **/
  
  func saveMapRegion() {
    let dictionary = [
      "latitude" : mapView.region.center.latitude,
      "longitude" : mapView.region.center.longitude,
      "latitudeDelta" : mapView.region.span.latitudeDelta,
      "longitudeDelta" : mapView.region.span.longitudeDelta
    ]
    NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
  }
  
  func restoreMapRegion(animated: Bool) {
    if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
      
      let longitude = regionDictionary["longitude"] as! CLLocationDegrees
      let latitude = regionDictionary["latitude"] as! CLLocationDegrees
      let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      
      let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
      let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
      let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
      
      let savedRegion = MKCoordinateRegion(center: center, span: span)
      mapView.setRegion(savedRegion, animated: animated)
    }
  }
  
  
  /** Mark: - Map Delegate **/
  
  func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
    self.saveMapRegion()
  }
  
  func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
    if let annotation = annotation as? Pin {
      let identifier = "pin"
      var view: MKPinAnnotationView
      
      if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
        dequeuedView.annotation = annotation
        view = dequeuedView
      }
      else{
        view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        view.canShowCallout = false // don't show any pin info when taped
        view.animatesDrop = true // drop effect for pin
        view.draggable = false // don't allow pin dragging
      }
      return view
    }
    return nil
  }
  
  func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
    // If the user is on the Edit mode
    if editButton.title == "Done" {
      let pin = view.annotation as! Pin
      // Delete the object from Core Data
      sharedContext.deleteObject(pin)
      // Remove the pin from the map
      mapView.removeAnnotation(pin)
      // Save the new context
      CoreDataStackManager.sharedInstance().saveContext()
    }
      // Otherwise go to the next view controller
    else {
      let controller = self.storyboard?.instantiateViewControllerWithIdentifier("LocationPhotos") as! LocationPhotos
      let pin = view.annotation as! Pin
      controller.receivedPin = pin
      self.navigationController?.pushViewController(controller, animated: true)
    }
  }
  
}