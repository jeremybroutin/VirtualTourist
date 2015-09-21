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
  
  /** Mark: - App Life Cycle **/
  
  var sharedContext: NSManagedObjectContext{
    return CoreDataStackManager.sharedInstance().managedObjectContext!
  }
  
  /** Mark: - App Life Cycle **/
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // set map delegate and restore last seen region
    mapView.delegate = self
    restoreMapRegion(false)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  /** Mark: - Drop a Pin **/
  
  @IBAction func tapHoldOnMap(gesturerecognizer: UILongPressGestureRecognizer) {
    
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
  
}