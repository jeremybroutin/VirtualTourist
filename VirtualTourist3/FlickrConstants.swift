//
//  FlickrConstants.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import Foundation

extension FlickrClient {
  
  // Constants
  struct Constants {
    static let APIKey = "6bd8646eaa369906b5a431cfd749d935"
    static let BaseURL = "https://api.flickr.com/services/rest/"
    static let SearchMethod = "flickr.photos.search"
    static let GetRecent = "flickr.photos.getRecent"
  }
  
  // Param Keys
  struct ParamKeys {
    static let APIKey = "api_key"
    static let Format = "format"
    static let Extras = "extras"
    static let Latitude = "latitude"
    static let Longitude = "longitude"
    static let Method = "method"
    static let NoJSONCallback = "nojsoncallback"
    static let Page = "page"
    static let PerPage = "per_page"
  }
  
  // Param Values
  struct ParamValues {
    static let JSONFormat = "json"
    static let URL_M = "url_m"
    static let NoJSONCallback = 1
    static let PerPage = 21
  }
  
  // JSON Response Keys
  struct JSONResponseKeys {
    static let Photos = "photos"
    static let Pages = "pages"
    static let Photo = "photo"
    static let URL_M = "url_m"
    static let Status = "status_message"
  }
  
}