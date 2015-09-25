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

class LocationPhotos: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
  
  /** Mark: - Outlets **/
  
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var collectionView: UICollectionView!
  @IBOutlet weak var newCollection: UIBarButtonItem!
  
  /** Mark: - Properties **/
  
  var receivedPin: Pin!
  // Arrays to keep track of selected or updated collection view cells
  var selectedIndexes   = [NSIndexPath]()
  var insertedIndexPaths: [NSIndexPath]!
  var deletedIndexPaths : [NSIndexPath]!
  var updatedIndexPaths : [NSIndexPath]!
  // Cell identifier
  var reuseIdentifier = "PhotoLocationCell"
  
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
    
    // fetch data to see if we already have pin photos
    fetchDataFromCoreData()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    // Check for the Pin Photos and load them if we don't have already
    if receivedPin.photos.isEmpty {
      FlickrClient.sharedInstance().getPhotosForPin(receivedPin, completionHandler: {
        success, error in
        if success {
          self.fetchDataFromCoreData()
          self.collectionView?.reloadData()
        }
        if let error = error {
          println(error)
        }
      })
      
    }
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
  /** Mark: - Actions **/
  
  @IBAction func tapNewCollectionButton(sender: UIBarButtonItem) {
    
    if selectedIndexes.count == 0 {
      loadNewPhotosCollection()
    }
    else{
      for index in selectedIndexes {
        // Capture photo object for each index
        let object = fetchedResultsController.objectAtIndexPath(index) as! Photo
        // Remove it from Core Data
        sharedContext.deleteObject(object)
        // Save context
        CoreDataStackManager.sharedInstance().saveContext()
        
        // And finally empty array and switch button title
        selectedIndexes = []
        println("index count after deletion is: \(selectedIndexes.count)")
        changeTextNewCollectionButton()
      }
    }
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
  
  // Utility function to reload the fetchedResultsController
  func fetchDataFromCoreData() {
    var error: NSError?
    fetchedResultsController.performFetch(&error)
    if let error = error {
      println("Error getting the data for the Pin")
    }
  }

  /**********************************************************************************************/
  /** Mark: - Utility methods **/
  
  func loadNewPhotosCollection() {
    
    // Disable new collection button
    newCollection.enabled = false
    
    // Start by deleting existing photos
    let currentPhotos = fetchedResultsController.fetchedObjects as! [Photo]
    for photo in currentPhotos{
      sharedContext.deleteObject(photo)
      collectionView.reloadData()
    }
    CoreDataStackManager.sharedInstance().saveContext()
    
    // Then get new photos
    FlickrClient.sharedInstance().getPhotosForPin(receivedPin, completionHandler: {
      success, error in
      if success {
        dispatch_async(dispatch_get_main_queue()){
          CoreDataStackManager.sharedInstance().saveContext()
          self.fetchDataFromCoreData()
          //self.collectionView.reloadData()
          self.newCollection.enabled = true
        }
      }
    })
  }
  
  func configureCell(cell: PhotoCell, photo: Photo) {
    
    //Make sure the activity indicator is on
    cell.activityIndicatorView.startAnimating()
    
    //start with the placeholder
    var photoImage = UIImage(named: "photoPlaceHolder")
    cell.imageView.image = photoImage
    cell.imageView.alpha = 0.5
    
    //Check if local image is available
    if let localImage = photo.image {
      dispatch_async(dispatch_get_main_queue()){
        cell.imageView.image = localImage
        cell.imageView.alpha = 1.0
        cell.activityIndicatorView.stopAnimating()
      }
    }
    //If not, then download it
    else{
      let task = FlickrClient.sharedInstance().taskForImage(photo.imageURL, completionHandler: {
        data, error in
        if let error = error {
          // print error
          println("Image download error: \(error.localizedDescription)")
          // Use the error image
          dispatch_async(dispatch_get_main_queue()){
            cell.imageView.image = UIImage(named: "noImage")
            cell.imageView.alpha = 1
            cell.activityIndicatorView.stopAnimating()
          }
        }
        if let data = data {
          // Create the image out of the data
          let image = UIImage(data: data)
          // Update the model
          photo.image = image
          // Update the cell on the main thread
          dispatch_async(dispatch_get_main_queue()){
            cell.imageView.image = image
            cell.imageView.alpha = 1.0
            cell.activityIndicatorView.stopAnimating()
          }
        }
      })
      cell.taskToCancelifCellIsReused = task
    }
  }
  
  func changeTextNewCollectionButton() {
    if selectedIndexes.count > 0 {
      newCollection.title = "Delete selected Photos"
    }
    else {
      newCollection.title = "New Collection"
    }
  }
  
}



/**********************************************************************************************/
/** Mark: - NSFetchedResultsController methods **/

extension LocationPhotos: NSFetchedResultsControllerDelegate {
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    
    //Prepare for changed content from Core Data
    insertedIndexPaths = [NSIndexPath]()
    deletedIndexPaths  = [NSIndexPath]()
    updatedIndexPaths  = [NSIndexPath]()
  }
  
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    
    //Add the indexPath of the changed objects to the appropriate array, depending on the type of change
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
    
    //Check to make sure UI elements are correctly displayed.
    if controller.fetchedObjects?.count > 0 {
      
      //noImagesLabel.hidden = true
      //newCollectionButton.enabled = true
    }
    
    //Make the relevant updates to the collectionView once Core Data has finished its changes.
    collectionView.performBatchUpdates({
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

