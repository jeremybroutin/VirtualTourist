//
//  FlickrClient.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import Foundation

class FlickrClient {
  
  /** Mark: - Shared Instance **/
  class func sharedInstance() -> FlickrClient {
    struct Singleton {
      static var sharedInstance = FlickrClient()
    }
    return Singleton.sharedInstance
  }
  
  /** Mark: - Shared Image Cache **/
  struct Caches {
    static let imageCache = ImageCache()
  }
  
  
  
}
