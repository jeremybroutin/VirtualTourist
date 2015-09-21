//
//  TaskCancelingCollectionCell.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import UIKit

class TaskCancelingTableViewCell : UICollectionViewCell {
  
  // The property uses a property observer. Any time its
  // value is set it canceles the previous NSURLSessionTask
  
  var imageName: String = ""
  
  var taskToCancelifCellIsReused: NSURLSessionTask? {
    
    didSet {
      if let taskToCancel = oldValue {
        taskToCancel.cancel()
      }
    }
  }
}
