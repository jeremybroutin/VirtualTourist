//
//  LocationPhotos.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationPhotos: UIViewController, MKMapViewDelegate {
  
  /** Mark: - Outlets **/
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var newCollection: UIBarButtonItem!
  
  /** Mark: - Properties **/
  
  var receivedPin: Pin!
  
  /** Mark: - Core Data Context **/
  
  var sharedContext: NSManagedObjectContext{
    return CoreDataStackManager.sharedInstance().managedObjectContext!
  }
  
  /** Mark: - App Life Cycle **/
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // set the map properly with pin (centered on pin and with user interaction disabled)
    mapView.delegate = self
    mapView.userInteractionEnabled = false
    mapView.addAnnotation(receivedPin)
    let mapRegion = MKCoordinateRegionMakeWithDistance(receivedPin.coordinate, 25000, 25000)
    mapView.region = mapRegion
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
  }
  
}
