//
//  Photo.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import UIKit
import CoreData

@objc(Photo)

class Photo : NSManagedObject {
  
  struct Keys {
    static let ImageURL = "url_m"
    static let ImageFilePath = "imageFilePath"
  }
  
  @NSManaged var imageURL: String
  @NSManaged var imageFilePath: String?
  @NSManaged var pin: Pin?
  
  override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
    super.init(entity: entity, insertIntoManagedObjectContext: context)
  }
  
  init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
    
    // Core Data
    let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
    super.init(entity: entity, insertIntoManagedObjectContext: context)
    
    // Dictionary
    imageURL = dictionary[Keys.ImageURL] as! String
    imageFilePath = imageURL.lastPathComponent as String
  }
  
  var image: UIImage? {
    
    get {
      return FlickrClient.Caches.imageCache.imageWithIdentifier(imageFilePath)
    }
    
    set {
      FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: imageFilePath!)
    }
  }
}
