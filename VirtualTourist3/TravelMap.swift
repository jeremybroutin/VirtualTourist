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
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
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
  // Get a reference to the NSUserDefaults class
  let preferences = NSUserDefaults.standardUserDefaults()
  
  /** Mark: - Core Data Context **/
  
  var sharedContext: NSManagedObjectContext{
    return CoreDataStackManager.sharedInstance().managedObjectContext!
  }
  
  /** Mark: - App Life Cycle **/
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //show the activity indicator until map is loaded
    activityIndicator.hidden = false
    activityIndicator.startAnimating()
    
    // set map delegate and restore last seen region
    mapView.delegate = self
    restoreMapRegion(false)
    mapView.addAnnotations(fetchAllPins())
    
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
    // show initial tip for new users -->
    
    // don't show the alert if the user already dismissed it in the past
    if preferences.stringForKey("tipDismissed") == nil {
      // only show the tip once per session
      if preferences.stringForKey("tipSeenInSession") == nil {
        
        // if not display the tip
        let title = "Virtual Tourist Help"
        let message = "Get started: Tap the map to drop a pin!"
        let action = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        let actionBis = UIAlertAction(title: "Don't show again",style: .Default) { (action) in
          // set and store the NSUserDefault tipDimissed value
          self.preferences.setValue("yes", forKey: "tipDismissed")
        }
        Alert.sharedInstance().createAlert(self, title: title, message: message, action: action, actionBis: actionBis)
        
        // set and store a NSUserDefault value for tipSeenInSession
        self.preferences.setValue("yes", forKey: "tipSeenInSession")
      }
    }
  }
  
  /** Mark: - IBActions **/
  
  var pinToBeAdded: Pin? = nil
  
  @IBAction func tapHoldOnMap(gesturerecognizer: UILongPressGestureRecognizer) {
    var touchPoint = gesturerecognizer.locationInView(self.mapView)
    var newCoord: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: self.mapView)
    
    switch gesturerecognizer.state{
    // user starts holding long press
    case .Began:
      // create a Pin which is also an Annotation
      let dictionary: [String: AnyObject] = [
        Pin.Keys.Latitude: newCoord.latitude,
        Pin.Keys.Longitude: newCoord.longitude
      ]
      //create a Pin object with coordinates from touch point
      pinToBeAdded = Pin(dictionary: dictionary, context: sharedContext)
      // add it to the map
      mapView.addAnnotation(pinToBeAdded)
    
      // user didn't release and drags pin around
      // see SO answer here: http://stackoverflow.com/questions/20595440/setting-mkannotation-coordinates-in-real-time
      // manual KVO notifications
    case .Changed:
      // update coordinates of the pin
      pinToBeAdded?.willChangeValueForKey("coordinate")
      pinToBeAdded?.coordinate = newCoord
      pinToBeAdded?.didChangeValueForKey("coordinate")
    
      // pin is dropped
    case .Ended:
      // download photos and images for the pin
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
    default:
      return
    }
  }
  
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
  
  /** Mark: - Convenience methods **/
  
  // Get all pins
  func fetchAllPins() -> [Pin] {
    let error: NSErrorPointer = nil
    let fetchRequest = NSFetchRequest(entityName: "Pin")
    let results: [AnyObject]?
    do {
      results = try sharedContext.executeFetchRequest(fetchRequest)
    } catch let error1 as NSError {
      error.memory = error1
      results = nil
    }
    
    return results as! [Pin]
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
  
  func mapViewDidFinishLoadingMap(mapView: MKMapView) {
    // stop and hide the activity indicator
    activityIndicator.stopAnimating()
    activityIndicator.hidden = true
  }
  
  func mapViewDidFailLoadingMap(mapView: MKMapView, withError error: NSError) {
    // stop and hide the activity indicator
    activityIndicator.stopAnimating()
    activityIndicator.hidden = true
    
    // create an alert in case the map could not be loaded
    let title = "The map could not be loaded"
    let message = "Check your connexion or retry later"
    let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
    Alert.sharedInstance().createAlert(self, title: title, message: message, action: action, actionBis: nil)
    //createAlert(title, message: message, action: action)
  }
  
  func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    self.saveMapRegion()
  }
  
  func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView! {
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
        view.draggable = false // cannot be dragged once dropped
      }
      return view
    }
    return nil
  }
  
  func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
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