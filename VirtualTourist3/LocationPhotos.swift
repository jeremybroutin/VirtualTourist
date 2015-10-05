//
//  LocationPhotos.swift
//  VirtualTourist3
//
//  Created by Jeremy Broutin on 9/21/15.
//  Copyright (c) 2015 Jeremy Broutin. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationPhotos: UIViewController, MKMapViewDelegate, UICollectionViewDelegate,
UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
  
  /** Mark: - Outlets **/
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var newCollection: UIBarButtonItem!
  @IBOutlet weak var noImage: UILabel!
  
  /** Mark: - Properties **/
  
  var receivedPin: Pin!
  // Arrays to keep track of selected or updated collection view cells
  var selectedIndexes   = [NSIndexPath]()
  var insertedIndexPaths: [NSIndexPath]!
  var deletedIndexPaths : [NSIndexPath]!
  var updatedIndexPaths : [NSIndexPath]!
  // Cell identifier
  var reuseIdentifier = "PhotoLocationCell"
  // Error message for fetching
  var errorfetchingMessage = "Oups, an error occured for this Pin! Try dropping another one."
  
  /** Mark: - Core Data Context **/
  
  var sharedContext: NSManagedObjectContext{
    return CoreDataStackManager.sharedInstance().managedObjectContext!
  }
  
  /**********************************************************************************************/
  
  /** Mark: - App Life Cycle **/
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // set the map properly with pin (centered on pin and with user interaction disabled)
    mapView.delegate = self
    mapView.userInteractionEnabled = false
    mapView.addAnnotation(receivedPin)
    let mapRegion = MKCoordinateRegionMakeWithDistance(receivedPin.coordinate, 25000, 25000)
    mapView.region = mapRegion
    
    // set the collection delegate and data source
    collectionView.delegate = self
    collectionView.dataSource = self
    
    // make sure the noImage label stays hidden
    noImage.hidden = true
    
    // start the fetched results controller
    var error: NSError?
    fetchedResultsController.performFetch(&error)
    
    // if it throws an error, inform users
    if let error = error {
      noImage.text = errorfetchingMessage
      noImage.hidden = false
      newCollection.enabled = false
    }
    // check if the fetched data is empty
    if fetchedResultsController.fetchedObjects?.count == 0 {
      //display label and disable new collection button
      noImage.hidden = false
      newCollection.enabled = false
    }
    fetchedResultsController.delegate = self
  }
  
  
  override func viewDidLayoutSubviews() {
    //Layout the collectionView cells properly on the View
    let layout = UICollectionViewFlowLayout()
    
    layout.sectionInset = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
    layout.minimumLineSpacing = 5
    layout.minimumInteritemSpacing = 5
    
    let width = (floor(self.collectionView.frame.size.width / 3)) - 7
    layout.itemSize = CGSize(width: width, height: width)
    collectionView.collectionViewLayout = layout
  }
  
  
    /**********************************************************************************************/
  
  /** Mark: - IBActions **/
  
  @IBAction func tapNewCollection(sender: AnyObject) {
    
    if selectedIndexes.count == 0 {
      // load new set of photos
      self.loadNewPhotos()
    }
    else {
      // delete selected photos
      for index in selectedIndexes {
        let photoToDelete = fetchedResultsController.objectAtIndexPath(index) as! Photo
        sharedContext.deleteObject(photoToDelete)
      }
      // clean selectedIndexes array
      selectedIndexes = []
      // change button text
      changeTextNewCollectionButton()
      // save everything
      CoreDataStackManager.sharedInstance().saveContext()
    }
  }
  
  /**********************************************************************************************/
  
  /** Mark: - Utility methods **/
  
  // Load cells with proper images
  func configureCell(cell: PhotoCell, photo: Photo) {
    
    // make sure the selectedicon is hidden
    cell.selectedIcon.hidden = true
    
    // start with the placeholder
    var photoImage = UIImage(named: "photoPlaceHolder")
    cell.activityIndicatorView.startAnimating()
    cell.imageView.image = photoImage
    cell.imageView.alpha = 0.5
    
    // check if local image is available
    if photo.imageFilePath != nil {
      if let localImage = photo.image {
        cell.imageView.image = localImage
        cell.imageView.alpha = 1.0
        cell.activityIndicatorView.stopAnimating()
      }
    }

  }
  
  // Handle bottom button title changes
  func changeTextNewCollectionButton() {
    if selectedIndexes.count > 0 {
      newCollection.title = "Delete selected Photos"
    }
    else {
      newCollection.title = "New Collection"
    }
  }
  
  // Query new photos when New Collection is tapped
  func loadNewPhotos() {
    
    // Disable new collection button if no results are returned
    newCollection.enabled = false
    
    // 1 - Delete existing photos
    for photo in fetchedResultsController.fetchedObjects as! [Photo]{
      sharedContext.deleteObject(photo)
    }
    CoreDataStackManager.sharedInstance().saveContext()
    
    // 2 - Get new set of photos
    FlickrClient.sharedInstance().getPhotosForPin(receivedPin, completionHandler: {
      success, error in
      if success{
        dispatch_async(dispatch_get_main_queue()){
          CoreDataStackManager.sharedInstance().saveContext()
          // Re enable new collection button
          self.newCollection.enabled = true
        }
      }
      else{
        dispatch_async(dispatch_get_main_queue()){
          self.noImage.hidden = false
          self.newCollection.enabled = false
        }
      }
    })
  }
  


  /**********************************************************************************************/

  /** Mark: - UICollectionViewDataSource  methods **/
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let sectionInfo = self.fetchedResultsController.sections?[section] as! NSFetchedResultsSectionInfo
    return sectionInfo.numberOfObjects
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCell
    let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
    
    configureCell(cell, photo: photo)

    return cell
  }

  
  /**********************************************************************************************/

  /** Mark: - UICollectionViewDelegate methods **/
  
  func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    // disable selection if the cell image is not ready yet
    let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
    if cell.activityIndicatorView.isAnimating() {
      return false
    }
    else {
      return true
    }
  }
  
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

  /**********************************************************************************************/
  
  /** Mark: - Fetch Results Controller **/
  
  lazy var fetchedResultsController: NSFetchedResultsController = {
    
    let fetchRequest = NSFetchRequest(entityName: "Photo")
    
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
    fetchRequest.predicate = NSPredicate(format: "pin == %@", self.receivedPin)
    
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
      managedObjectContext: self.sharedContext,
      sectionNameKeyPath: nil,
      cacheName: nil)
    
    return fetchedResultsController
    
    }()
  
  
  /**********************************************************************************************/
  
  /** Mark: - NSFetchedResultsController Delegate **/
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    
    insertedIndexPaths = [NSIndexPath]()
    deletedIndexPaths  = [NSIndexPath]()
    updatedIndexPaths  = [NSIndexPath]()

  }
  
  func controller(controller: NSFetchedResultsController,
    didChangeObject anObject: AnyObject,
    atIndexPath indexPath: NSIndexPath?,
    forChangeType type: NSFetchedResultsChangeType,
    newIndexPath: NSIndexPath?) {
      
      switch type {
      case .Insert:
        insertedIndexPaths.append(newIndexPath!)
      case .Delete:
        deletedIndexPaths.append(indexPath!)
      case .Update:
        updatedIndexPaths.append(indexPath!)
      default:
        break
      }
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    
    // Hide/Enable items consequent to the changes
    if controller.fetchedObjects?.count > 0 {
      noImage.hidden = true
      newCollection.enabled = true
    }
    
    // Perform updates into the collectionView
    collectionView.performBatchUpdates({() -> Void in
      for indexPath in self.insertedIndexPaths {
        self.collectionView.insertItemsAtIndexPaths([indexPath])
      }
      for indexPath in self.deletedIndexPaths {
        self.collectionView.deleteItemsAtIndexPaths([indexPath])
      }
      for indexPath in self.updatedIndexPaths {
        self.collectionView.reloadItemsAtIndexPaths([indexPath])
      }
      }, completion: nil)
  }
}

