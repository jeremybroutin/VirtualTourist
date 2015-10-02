//
//  Alert.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 10/2/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import Foundation
import UIKit

class Alert: NSObject {
  
  // Create alert
  func createAlert(hostViewController: UIViewController, title: String, message: String, action: UIAlertAction?, actionBis: UIAlertAction?) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
    let action = action
    if let actionBis = actionBis {
      alertController.addAction(actionBis)
    }
    alertController.addAction(action!)
    hostViewController.presentViewController(alertController, animated: true, completion: nil)
  }
  
  /** Mark: - Shared Instance **/
  
  class func sharedInstance() -> Alert {
    struct Singleton {
      static var sharedInstance = Alert()
    }
    return Singleton.sharedInstance
  }
}
