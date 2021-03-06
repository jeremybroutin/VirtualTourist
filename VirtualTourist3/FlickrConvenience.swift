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
      let numberOfPagesAsInt = numberOfPages as Int
      randomPage = Int((arc4random_uniform(UInt32(numberOfPagesAsInt)))) + 1
      // + 1 avoid returning the page 0 which doesn't exist
    }
    
    // Set the parameters to be used in FlickR request
    let parameters: [String: AnyObject] = [
      FlickrClient.ParamKeys.APIKey: FlickrClient.Constants.APIKey,
      FlickrClient.ParamKeys.Method: FlickrClient.Constants.SearchMethod,
      FlickrClient.ParamKeys.Format: FlickrClient.ParamValues.JSONFormat,
      FlickrClient.ParamKeys.NoJSONCallback: FlickrClient.ParamValues.NoJSONCallback,
      FlickrClient.ParamKeys.Latitude: pin.latitude,
      FlickrClient.ParamKeys.Longitude: pin.longitude,
      FlickrClient.ParamKeys.Extras: FlickrClient.ParamValues.URL_M,
      FlickrClient.ParamKeys.Page: randomPage,
      FlickrClient.ParamKeys.PerPage: FlickrClient.ParamValues.PerPage
    ]
    
    // Start task to download photos
    taskForResources(parameters) { result, error in
      if let error = error {
        completionHandler(success: false, error: error)
      }
      else {
        
        if let photosDictionary = result.valueForKey(FlickrClient.JSONResponseKeys.Photos) as? [String:AnyObject],
          let photosArray = photosDictionary[FlickrClient.JSONResponseKeys.Photo] as? [[String: AnyObject]],
          let numberOfPhotoPages = photosDictionary[FlickrClient.JSONResponseKeys.Pages] as? Int {
            
            // Save and store the number of pages returned for the pin
            pin.numberOfPages = numberOfPhotoPages
            
            // Get photo url for each photo in returned array
            var photos = photosArray.map() { (dictionary: [String: AnyObject]) -> Photo in
              let photo = Photo(dictionary: dictionary, context: self.sharedContext)
              
              //get image for the photo
              self.getImageForPhoto(photo, completionHandler: {
                success, error in
                dispatch_async(dispatch_get_main_queue()){
                  CoreDataStackManager.sharedInstance().saveContext()
                }
              })
              photo.pin = pin
              return photo
            }
            completionHandler(success: true, error: nil)
        } // end of if let photosDictionary
        else {
          let error = NSError(domain: "Photo for Pin Parsing. Cant find photo in \(result)", code: 0, userInfo: nil)
          completionHandler(success: false, error: error)
        }
      }
    }
  }
  
  // Helper function to get 
  func getImageForPhoto(photo: Photo, completionHandler: (success: Bool, error: NSError?)-> Void) {
    
    let imageURL = photo.imageURL
    
    taskForImage(imageURL!, completionHandler: {
      imageData, error in
      if let error = error {
        completionHandler(success: false, error: error)
      }
      if let imageData = imageData {
        let image = UIImage(data: imageData)
        
        // store image file in document directory
        let fileName = imageURL!.lastPathComponent
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
        let pathArray = [dirPath, fileName]
        let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
        NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: imageData, attributes: nil)
        
        // attach the newly saved image data to the photo object
        photo.imageFilePath = fileURL.path
        
        completionHandler(success: true, error: nil)
      }
      
    })
  }
  
}