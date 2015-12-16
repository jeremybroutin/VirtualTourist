# VirtualTourist
## Description
Udacity iOS Developer Nanodegree - 4th project: iOS Core Persistence
VirtualTourist lets you drop a pin on a world map and returns related FlickR pictures for the pinned location.
## App content
As we progressed further into the iOS Nanodegree, this app includes:
- a mapView and its delegate methods to drop, tap and delete pins
- a network request to the FlickR API which returns a JSON file with photos data
- a collectionView to display the returned photos from the FlickR API request
- 2 core data objects with a one-to-many relationship to store Pins and their related Photos
- multiple core data fetch requests, a fetchedResultsController and its delegate to save and delete objects
- an access to the NSUserDefaults to store small piece of information (eg: first time user or not to display a welcome alert)
- an access to the device Documents directory to store the image file of the Photos

