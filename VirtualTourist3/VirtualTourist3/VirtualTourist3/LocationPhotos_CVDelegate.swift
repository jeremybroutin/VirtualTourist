//
//  LocationPhotos_CVDelegate.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/25/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import Foundation
import UIKit

extension LocationPhotos: UICollectionViewDelegate {
  
  func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
    let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
    
    // if touched image was already selected, unselect it and remove it from selectedIndexes...
    if let index = find(selectedIndexes, indexPath) {
      selectedIndexes.removeAtIndex(index)
      
      // ... and unhiglight it
      cell.selectedIcon.hidden = true
      UIView.animateWithDuration(0.1, animations: {
        cell.imageView.alpha = 1.0
      })
    }
      // otherwise add it to the selectedIndexes...
    else{
      selectedIndexes.append(indexPath)
      // ... and highlight its selection (reduce alpha and display check mark)
      cell.selectedIcon.hidden = false
      UIView.animateWithDuration(0.1, animations: {
        cell.imageView.alpha = 0.5
      })
    }
    // Update the new collection button title consequently
    changeTextNewCollectionButton()
  }
  
}