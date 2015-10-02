//
//  CoreDataStackManager.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import Foundation
import CoreData

private let SQLITE_FILE_NAME = "VirtualTourist3.sqlite"

class CoreDataStackManager {
  
  
  // MARK: - Shared Instance
  
  class func sharedInstance() -> CoreDataStackManager {
    struct Static {
      static let instance = CoreDataStackManager()
    }
    
    return Static.instance
  }
  
  // MARK: - The Core Data stack. The code has been moved, unaltered, from the AppDelegate.
  
  lazy var applicationDocumentsDirectory: NSURL = {
    
    let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    return urls[urls.count-1] as! NSURL
    }()
  
  lazy var managedObjectModel: NSManagedObjectModel = {
    // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
    
    let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
    return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
  
  
  lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
    
    var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
    let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent(SQLITE_FILE_NAME)
    
    println("sqlite path: \(url.path!)")
    
    var error: NSError? = nil
    
    if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
      coordinator = nil
      // Report any error we got.
      let dict = NSMutableDictionary()
      dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
      dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."
      dict[NSUnderlyingErrorKey] = error
      error = NSError(domain: "VirtualTourist3", code: 9999, userInfo: dict as [NSObject : AnyObject])
      
      // Left in for development development.
      NSLog("Unresolved error \(error), \(error!.userInfo)")
      abort()
    }
    
    return coordinator
    }()
  
  lazy var managedObjectContext: NSManagedObjectContext? = {

    let coordinator = self.persistentStoreCoordinator
    if coordinator == nil {
      return nil
    }
    var managedObjectContext = NSManagedObjectContext()
    managedObjectContext.persistentStoreCoordinator = coordinator
    return managedObjectContext
    }()
  
  // MARK: - Core Data Saving support
  
  func saveContext () {
    
    if let context = self.managedObjectContext {
      
      var error: NSError? = nil
      
      if context.hasChanges && !context.save(&error) {
        NSLog("Unresolved error \(error), \(error!.userInfo)")
        abort()
      }
    }
  }
}
