//
//  TaskCancelingCollectionCell.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import Foundation
import UIKit

class PhotoCell : UICollectionViewCell {
  
  // The property uses a property observer. Any time its
  // value is set it canceles the previous NSURLSessionTask
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
  @IBOutlet weak var selectedIcon: UIImageView!
  
  var taskToCancelifCellIsReused: NSURLSessionTask? {
    
    didSet {
      if let taskToCancel = oldValue {
        taskToCancel.cancel()
      }
    }
  }
  
  var image: UIImage?{
    set{
      self.imageView.image = newValue
    }
    get{
      return self.imageView.image ?? nil
    }
  }
}
