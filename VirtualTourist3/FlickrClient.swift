//
//  FlickrClient.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
  
  /** Mark: - Properties**/
  typealias CompletionHander = (result: AnyObject!, error: NSError?) -> Void
  var session: NSURLSession
  
  override init(){
    session = NSURLSession.sharedSession()
    super.init()
  }
  
  /** Mark: - Shared Instance **/
  
  class func sharedInstance() -> FlickrClient {
    struct Singleton {
      static var sharedInstance = FlickrClient()
    }
    return Singleton.sharedInstance
  }
  
  /** Mark: - Client helper methods **/
  
  func taskForResources(parameters: [String:AnyObject], completionHandler: CompletionHander) -> NSURLSessionDataTask {
    
    // Build the request
    let urlString = Constants.BaseURL + FlickrClient.escapedParameters(parameters)
    let url = NSURL(string: urlString)
    let request = NSURLRequest(URL: url!)
    
    // Initiate task
    let task = session.dataTaskWithRequest(request){ data, response, downloadError in
      if let error = downloadError {
        let newError = FlickrClient.errorForData(data, response: response, error: error)
        completionHandler(result: nil, error: downloadError)
      }
      else{
        FlickrClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
      }
    }
    task.resume()
    return task
  }
  
  func taskForImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) -> Void) -> NSURLSessionTask {
    let urlString = filePath
    let url = NSURL(string: urlString)
    let request = NSURLRequest(URL: url!)
    
    let task = session.dataTaskWithRequest(request){ data, response, downloadError in
      if let error = downloadError {
        let newError = FlickrClient.errorForData(data, response: response, error: error)
        completionHandler(imageData: nil, error: newError)
      }
      else{
        completionHandler(imageData: data, error: nil)
      }
    }
    task.resume()
    return task
  }
  
  /** Helper function: Given a dictionary of parameters, convert it to a string for a url **/
  class func escapedParameters(parameters: [String : AnyObject]) -> String {
    
    var urlVars = [String]()
    
    for (key, value) in parameters {
      
      let stringValue = "\(value)"
      let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())
      let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: .LiteralSearch, range: nil)
      urlVars += [key + "=" + "\(replaceSpaceValue)"]
    }
    
    return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
  }
  
  /** Try to make a better error, based on the status_message from TheMovieDB. If we cant then return the previous error **/
  class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
    
    if let parsedResult = (try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)) as? [String : AnyObject] {
      if let errorMessage = parsedResult[JSONResponseKeys.Status] as? String {
        
        let userInfo = [NSLocalizedDescriptionKey : errorMessage]
        
        return NSError(domain: "VirtualTourist3 Error", code: 1, userInfo: userInfo)
      }
    }
    
    return error
  }
  
  /** Parsing the JSON **/
  class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHander) {
    var parsingError: NSError? = nil
    
    let parsedResult: AnyObject?
    do {
      parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
    } catch let error as NSError {
      parsingError = error
      parsedResult = nil
    }
    
    if let error = parsingError {
      completionHandler(result: nil, error: error)
    } else {
      completionHandler(result: parsedResult, error: nil)
    }
  }
  
  
}
