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
          numberOfPhotoPages = photosDictionary[JSONResponseKeys.Pages] as? Int,
          photosArray = photosDictionary[JSONResponseKeys.Photo] as? [[String: AnyObject]] {
            
            // Save and store the number of pages returned for the pin
            pin.numberOfPages = numberOfPhotoPages
            
            // Get photo url for each photo in returned array
            var photos = photosArray.map() { (dictionary: [String: AnyObject]) -> Photo in
              let photo = Photo(dictionary: dictionary, context: self.sharedContext)
              photo.pin = pin
              return photo              
            }
            dispatch_async(dispatch_get_main_queue()) {
              // handler.collectionView.reloadData()
            }
        }
      }
    }
  }
  
}