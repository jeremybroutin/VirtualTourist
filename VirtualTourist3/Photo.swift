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
    static let ID = "id"
  }
  
  @NSManaged var imageURL: String?
  @NSManaged var imageFilePath: String?
  @NSManaged var id: String
  @NSManaged var pin: Pin?
  
  override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
    super.init(entity: entity, insertIntoManagedObjectContext: context)
  }
  
  init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
    
    // Core Data
    let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
    super.init(entity: entity, insertIntoManagedObjectContext: context)
    
    // Dictionary
    imageURL = dictionary[Keys.ImageURL] as? String
    //imageFilePath = imageURL.lastPathComponent as String
    id = dictionary[Keys.ID] as! String
  }
  
  var image: UIImage? {
    
    if let imageFilePath = imageFilePath {
      let fileName = imageFilePath.lastPathComponent
      let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
      let pathArray = [dirPath, fileName]
      let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
      
      return UIImage(contentsOfFile: fileURL.path!)
    }
    else {
      return UIImage(named: "noImage")
    }
    
    /**
    get {
      if let url = imageURL {
        return FlickrClient.Caches.imageCache.imageWithIdentifier(url.lastPathComponent)
      }
      else {
        return UIImage(named: "noImage")
      }
    }
    set {
      if let url = imageURL {
        FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: url.lastPathComponent)
      }
    }**/
  }
  
  // Thanks to paul_288661
  // https://discussions.udacity.com/t/virtual-tourist-empty-an-array-in-an-nsmanagedobject/29447/7
  
  override func prepareForDeletion() {
    
    //Delete the associated image file when the Photo managed object is deleted.
    if let fileName = imageFilePath?.lastPathComponent {
      
      let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
      let pathArray = [dirPath, fileName]
      let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
      
      NSFileManager.defaultManager().removeItemAtURL(fileURL, error: nil)
    }
  }}
