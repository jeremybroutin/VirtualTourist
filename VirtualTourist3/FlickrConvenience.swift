//
//  FlickrConvenience.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import Foundation
import MapKit
import CoreData

extension FlickrClient {
  
  /** Mark: - Core Data Context **/
  
  var sharedContext: NSManagedObjectContext{
    return CoreDataStackManager.sharedInstance().managedObjectContext!
  }
  
  /** Mark: - Convenience Methods **/
  
  func getPhotosForPin(pin: Pin, completionHandler: (success: Bool, error: NSError?) -> Void) {
    
    // Chose a random page to query photos from FlickR
    var randomPage = 1
    if let numberOfPages = pin.numberOfPages {
      // Because pin.numberOfPages is a NSNumber, we need to downcast it to an Int
      let numberOfPagesAsInt = numberOfPages as! Int
      randomPage = Int((arc4random_uniform(UInt32(numberOfPagesAsInt)))) + 1
      // + 1 avoid returning the page 0 which doesn't exist
    }
    
    println("pinNumberOfPages: \(pin.numberOfPages)")
    
    // Set the parameters to be used in FlickR request
    let parameters: [String: AnyObject] = [
      ParamKeys.APIKey: Constants.APIKey,
      ParamKeys.Method: Constants.SearchMethod,
      ParamKeys.Format: ParamValues.JSONFormat,
      ParamKeys.NoJSONCallback: ParamValues.NoJSONCallback,
      ParamKeys.Latitude: pin.latitude,
      ParamKeys.Longitude: pin.longitude,
      ParamKeys.Extras: ParamValues.URL_M,
      ParamKeys.Page: randomPage,
      ParamKeys.PerPage: ParamValues.PerPage
    ]
    
    // Call taskForResources to initiate task
    taskForResources(parameters) { results, error in
      if let error = error {
        completionHandler(success: false, error: error)
      }
      else{
        if let photosDictionary = results.valueForKey(JSONResponseKeys.Photos) as? [String:AnyObject],
          photosArray = photosDictionary[JSONResponseKeys.Photo] as? [[String: AnyObject]] {
            
            println("all good")
            // Save and store the number of pages returned for the pin
            pin.numberOfPages = photosDictionary[JSONResponseKeys.Pages] as? Int
            
            // Get photo url for each photo in returned array
            var photos = photosArray.map() { (dictionary: [String: AnyObject]) -> Photo in
              let photo = Photo(dictionary: dictionary, context: self.sharedContext)
              
              self.getImageForPhoto(photo, completionHandler: {
                success, error in
                dispatch_async(dispatch_get_main_queue()){
                  CoreDataStackManager.sharedInstance().saveContext()
                }
              })
              
              photo.pin = pin
              return photo              
            }

        }
      }
    }
  }
  
  func getImageForPhoto(photo: Photo, completionHandler: (success: Bool, error: NSError?) -> Void){
    let imageURLString = photo.imageURL
    taskForImage(imageURLString){ imageData, error in
      if let error = error {
        photo.imageFilePath = "error"
        println("Error getting image for Photo on pin drop")
        completionHandler(success: false, error: error)
      }
      else{
        if let imageData = imageData {
          let fileName = imageURLString.lastPathComponent
          let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
          let pathArray = [dirPath, fileName]
          let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
          
          NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: imageData, attributes: nil)
          photo.imageFilePath = fileURL.path
          
          completionHandler(success: true, error: nil)
        }
      }
    }
  }
  
}