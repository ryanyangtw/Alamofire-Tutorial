//
//  PhotoBrowserCollectionViewController.swift
//  Photomania
//
//  Created by Essan Parto on 2014-08-20.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import Alamofire

class PhotoBrowserCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
  var photos = NSMutableOrderedSet()
  
  let refreshControl = UIRefreshControl()
  
  // There are two variables to keep track of whether you;re currently populating photos, and what the current page of photos is.
  var populatingPhotos = false
  var currentPage = 1
  
  let PhotoBrowserCellIdentifier = "PhotoBrowserCell"
  let PhotoBrowserFooterViewIdentifier = "PhotoBrowserFooterView"
  
  // MARK: Life-cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupView()
    
    populatePhotos()
    
    // responsePropertyList, responseString
    /*
    Alamofire.request(.GET, "https://api.500px.com/v1/photos", parameters: ["consumer_key": "zSxP3SHwZRxLi2KlGGBOTzhc6JkNETH7F0qLQQ3Q"]).responseJSON() {
      (_, _, JSON, _) in
      
      
      // [NSDictionary]
      let photoInfos = (JSON!.valueForKey("photos") as! [[String: AnyObject]]).filter({
          ($0["nsfw"] as! Bool) == false
      }).map {
        PhotoInfo(id: $0["id"] as! Int, url: $0["image_url"] as! String)
      }
      
      self.photos.addObjectsFromArray(photoInfos)
      self.collectionView!.reloadData()
      

      //println(JSON)
    }
    */
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: CollectionView
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return photos.count
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(PhotoBrowserCellIdentifier, forIndexPath: indexPath) as! PhotoBrowserCollectionViewCell
    
    let imageURL = (photos.objectAtIndex(indexPath.row) as! PhotoInfo).url
    
    // When you dequeue a cell, you invalidate the image by setting it to nil. This ensures you're not displaying the previous image. Second, you cancel the previous request(if still in progess) to avoid wasting cycles for getting an image that will be discarded
    cell.imageView.image = nil
    cell.request?.cancel()
    
    cell.request = Alamofire.request(.GET, imageURL).responseImage() {
      (request, _, image, error) in
      if error == nil && image != nil {
        cell.imageView.image = image
      }
    }
    
    /*
    Alamofire.request(.GET, imageURL).response() {
      (_, _, data, _) in
      
      let image = UIImage(data: data! as! NSData)
      cell.imageView.image = image
    }
    */
    
    return cell
  }
  
  override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
    return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: PhotoBrowserFooterViewIdentifier, forIndexPath: indexPath) as! UICollectionReusableView
  }
  
  override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    performSegueWithIdentifier("ShowPhoto", sender: (self.photos.objectAtIndex(indexPath.item) as! PhotoInfo).id)
  }
  
  // MARK: Helper
  
  func setupView() {
    navigationController?.setNavigationBarHidden(false, animated: true)
    
    let layout = UICollectionViewFlowLayout()
    let itemWidth = (view.bounds.size.width - 2) / 3
    layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
    layout.minimumInteritemSpacing = 1.0
    layout.minimumLineSpacing = 1.0
    layout.footerReferenceSize = CGSize(width: collectionView!.bounds.size.width, height: 100.0)
    
    collectionView!.collectionViewLayout = layout
    
    navigationItem.title = "Featured"
    
    collectionView!.registerClass(PhotoBrowserCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: PhotoBrowserCellIdentifier)
    collectionView!.registerClass(PhotoBrowserCollectionViewLoadingCell.classForCoder(), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: PhotoBrowserFooterViewIdentifier)
    
    refreshControl.tintColor = UIColor.whiteColor()
    refreshControl.addTarget(self, action: "handleRefresh", forControlEvents: .ValueChanged)
    collectionView!.addSubview(refreshControl)
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "ShowPhoto" {
      (segue.destinationViewController as! PhotoViewerViewController).photoID = sender!.integerValue
      (segue.destinationViewController as! PhotoViewerViewController).hidesBottomBarWhenPushed = true
    }
  }
  
  // 1. scrollViewDidScroll() loads more photos once you;ve scrolled through 80% of the view
  override func scrollViewDidScroll(scrollView: UIScrollView) {
    println("scrollView.contentOffset.y: \(scrollView.contentOffset.y)")
    println("view.frame.size.height: \(view.frame.size.height)")
    println("scrollView.contentSize.height: \(scrollView.contentSize.height)")
    if scrollView.contentOffset.y + view.frame.size.height > scrollView.contentSize.height * 0.8 {
      println("in scrollViewDidScroll")
      populatePhotos()
    }
  }
  
  func populatePhotos() {
  
    // 2. populatePhotos() loads photos in the currentPage and uses populatingPhotos as a flag to avoid loading the next page while you're still loading the current page.
    if populatingPhotos {
      return
    }
    
    populatingPhotos = true
    
    // 3. You simply pass in the page number and it constructs the URL string for that page.
    Alamofire.request(Five100px.Router.PopularPhotos(self.currentPage)).responseJSON() {
      (_, _, JSON, error) in
      
   
      if error == nil {
        // 4. Make careful note that the cmopletion handler the trailing closure of responseJSON must run on the main thread. If you;re performing any long-running operations, such as making an API call, you musst use GCD to dispath your code on another queue.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
          // 5. You're intersted in the photos key of the JSON response that includes an array of dictionaries. Each dictionary in the array contains information about one photo.
          // 6. Here you use filter function out NSFW(Not Safe For Work) images.
          // 7. The map function takes a closure and returns an array of PhotoInfo objects. if you lok at the code of this class, you'll see that it overrides both isEqual and hash. Both oh these mehotds use an inteher for the id property so ordering and uniquing PhotoInfo objects will still be a relatively fast operation.

          let pohtoInfos = ((JSON as! [String: AnyObject])["photos"] as! [[String: AnyObject]]).filter({
            ($0["nsfw"] as! Bool) == false
          }).map {
            PhotoInfo(id: $0["id"] as! Int, url: $0["image_url"] as! String)
          }
          
          // 8. You store the current number of photos before you add the new betch; you will use this to update collectionView
          let lastItem = self.photos.count
          
          // 9. if someone uploaded new photos to 500px.com before you scrolled, the next batch of photos you get might contain a few photos that you;d already download. That's why you defined photos to NSMutableOrdedSet() as a set, since all items in a set must be unique, this guarantees you won't show a photo more than once.
          // 只要photo id 一樣，就會被set視為同個物件，不會將其重複加入集合中
          self.photos.addObjectsFromArray(pohtoInfos)
          
          // 10. Create an array of NSIndexPath objects to insert into collectionView
          let indexPaths = (lastItem..<self.photos.count).map {
            NSIndexPath(forItem: $0, inSection: 0)
          }
          
          // 11. Insert the items in the collection view - but does on the main queue, because all UIKit operations must be done on teh main queue.
          dispatch_async(dispatch_get_main_queue()) {
            self.collectionView!.insertItemsAtIndexPaths(indexPaths)
          }
          
          self.currentPage++
        
        }
      } else {
        println("error")
      }
      self.populatingPhotos = false
    }
  }
  
  func handleRefresh() {
    
  }
}

class PhotoBrowserCollectionViewCell: UICollectionViewCell {
  let imageView = UIImageView()
  
  // This will store the Alamofire request to load the image for this cell
  // request 綁在 cell 裡，才能針對某一cell cancel request
  var request: Alamofire.Request?
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    backgroundColor = UIColor(white: 0.1, alpha: 1.0)
    
    imageView.frame = bounds
    addSubview(imageView)
  }
}

class PhotoBrowserCollectionViewLoadingCell: UICollectionReusableView {
  let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    spinner.startAnimating()
    spinner.center = self.center
    addSubview(spinner)
  }
}
