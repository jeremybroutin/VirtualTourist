//
//  Pin.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import UIKit
import MapKit
import CoreData

@objc(Pin)

class Pin: NSManagedObject, MKAnnotation {
  
  struct Keys {
    static let Latitude = "latitude"
    static let Longitude = "longitude"
    static let NumberOfPages = "numberOfPages"
  }
  
  @NSManaged var latitude: Double
  @NSManaged var longitude: Double
  @NSManaged var numberOfPages: NSNumber?
  @NSManaged var photos: [Photo]
  
  var coordinate: CLLocationCoordinate2D {
    
    set {
      self.latitude = newValue.latitude
      self.longitude = newValue.longitude
    }
    
    get {
      return CLLocationCoordinate2DMake(latitude, longitude)
    }
  }
  
  // Standard Core Data init method.
  override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
    super.init(entity: entity, insertIntoManagedObjectContext: context)
  }
  
  init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
    
    // Get the entity associated with the "Person" type.  This is an object that contains
    // the information from the Model.xcdatamodeld file.
    let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
    
    // Now we can call an init method that we have inherited from NSManagedObject. Remember that
    // the Person class is a subclass of NSManagedObject. This inherited init method does the
    // work of "inserting" our object into the context that was passed in as a parameter
    super.init(entity: entity,insertIntoManagedObjectContext: context)
    
    // After the Core Data work has been taken care of we can init the properties from the
    // dictionary. This works in the same way that it did before we started on Core Data
    latitude = dictionary[Keys.Latitude] as! Double
    longitude = dictionary[Keys.Longitude] as! Double
  }

  
}
