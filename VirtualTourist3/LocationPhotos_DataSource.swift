//
//  LocationPhotos_DataSource.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/25/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension LocationPhotos: UICollectionViewDataSource {
  
  /** Mark: - UICollectionViewDataSource  methods **/
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let sectionInfo = self.fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo {
      return sectionInfo.numberOfObjects
    }
    return 1
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCell
    let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
    
    configureCell(cell, photo: photo)
    return cell
  }
  
}
