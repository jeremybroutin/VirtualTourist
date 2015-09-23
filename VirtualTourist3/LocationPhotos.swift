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
    var error: NSError?
    fetchedResultsController.performFetch(&error)
    if let error = error {
      println("Error getting the data for the Pin")
    }
    fetchedResultsController.delegate = self
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    /**
    if receivedPin.photos.isEmpty {
    
      // Chose a random page to query photos from FlickR
      var randomPage = 1
      if let numberOfPages = receivedPin.numberOfPages {
        // Because pin.numberOfPages is a NSNumber, we need to downcast it to an Int
        let numberOfPagesAsInt = numberOfPages as! Int
        randomPage = Int((arc4random_uniform(UInt32(numberOfPagesAsInt)))) + 1
        // + 1 avoid returning the page 0 which doesn't exist
      }
      
      // Set the parameters to be used in FlickR request
      let parameters: [String: AnyObject] = [
        FlickrClient.ParamKeys.APIKey: FlickrClient.Constants.APIKey,
        FlickrClient.ParamKeys.Method: FlickrClient.Constants.GetRecent,
        FlickrClient.ParamKeys.Format: FlickrClient.ParamValues.JSONFormat,
        FlickrClient.ParamKeys.NoJSONCallback: FlickrClient.ParamValues.NoJSONCallback,
        FlickrClient.ParamKeys.Latitude: receivedPin.latitude,
        FlickrClient.ParamKeys.Longitude: receivedPin.longitude,
        FlickrClient.ParamKeys.Extras: FlickrClient.ParamValues.URL_M,
        FlickrClient.ParamKeys.Page: randomPage,
        FlickrClient.ParamKeys.PerPage: FlickrClient.ParamValues.PerPage
      ]
      
      // Start task to download photos
      
      FlickrClient.sharedInstance().taskForResources(parameters) { result, error in
        if let error = error {
          println(error)
        }
        else {
          
          if let photosDictionary = result.valueForKey(FlickrClient.JSONResponseKeys.Photos) as? [String:AnyObject],
            let photosArray = photosDictionary[FlickrClient.JSONResponseKeys.Photo] as? [[String: AnyObject]],
            let numberOfPhotoPages = photosDictionary[FlickrClient.JSONResponseKeys.Pages] as? Int {
              
              // Save and store the number of pages returned for the pin
              self.receivedPin.numberOfPages = numberOfPhotoPages
              
              // Get photo url for each photo in returned array
              var photos = photosArray.map() { (dictionary: [String: AnyObject]) -> Photo in
                let photo = Photo(dictionary: dictionary, context: self.sharedContext)
                photo.pin = self.receivedPin
                // println("photo is: \(photo)")
                return photo
              }
              
              /** Other way to proceed
              
              for photoEntry in photosArray {
              let photoURL = photoEntry[FlickrClient.JSONResponseKeys.URL_M] as! String
              let dictionary: [String: AnyObject] = [
              Photo.Keys.ImageURL: photoURL
              ]
              let newPhoto = Photo(dictionary: dictionary, context: self.sharedContext)
              newPhoto.pin = self.receivedPin
              
              }
              **/
              
              dispatch_async(dispatch_get_main_queue()){
                CoreDataStackManager.sharedInstance().saveContext()
                self.collectionView.reloadData()
              }
              
          } // end of if let photosDictionary
          else {
            let error = NSError(domain: "Photo for Pin Parsing. Cant find photo in \(result)", code: 0, userInfo: nil)
            println(error)
          }
        }
      }
    } // end of if Pin Photos is empty**/
  } // end of viewWillAppear
  
  /** Mark: - Core Data Context **/
  
  var sharedContext: NSManagedObjectContext{
    return CoreDataStackManager.sharedInstance().managedObjectContext!
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
  
  /** Mark: - Configure cell **/
  
  func configureCell(cell: PhotoCell, photo: Photo) {
    
    var photoImage = UIImage(named: "photoPlaceHolder")
    cell.imageView!.image = nil
    
    if photo.imageFilePath == nil || photo.imageFilePath == "" {
      photoImage = UIImage(named: "noImage")
    }
    else if photo.image != nil {
      println("photo.image != nil")
      photoImage = photo.image
    }
    else {
      
      // Download image
      let task = FlickrClient.sharedInstance().taskForImage(photo.imageURL){ data, error in
        if let error = error {
          println("Image download error: \(error.localizedDescription)")
        }
        if let data = data {
          // Create the image
          let image = UIImage(data: data)
          // Update the model for the info to be cashed
          photo.image = image
          // Update the cell later on the main thread
          dispatch_async(dispatch_get_main_queue()){
            cell.imageView.image = image
          }
        }
      }
      cell.taskToCancelifCellIsReused = task
    }
    cell.imageView.image = photoImage
  }
  
  /** Mark: - NSFetchedresults delegate methods **/
  // Will be added later
  
}

extension LocationPhotos: UICollectionViewDataSource {
  
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let sectionInfo = self.fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo {
      
      //debug
      println("sectionInfo Number of Objects is: \(sectionInfo.numberOfObjects)")
      
      return sectionInfo.numberOfObjects
    }
    return 1
  }
  
  func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCell
    let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
    println("fetched photo is: \(photo)")
    
    // debug: trying to simply show placeholders
    cell.imageView.image = UIImage(named: "photoPlaceHolder")
    
    //configureCell(cell, photo: photo)
    return cell
  }
}
