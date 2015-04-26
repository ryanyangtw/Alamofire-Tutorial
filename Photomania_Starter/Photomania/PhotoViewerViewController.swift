//
//  PhotoViewerViewController.swift
//  Photomania
//
//  Created by Essan Parto on 2014-08-24.
//  Copyright (c) 2014 Essan Parto. All rights reserved.
//

import UIKit
import QuartzCore
import Alamofire

class PhotoViewerViewController: UIViewController, UIScrollViewDelegate, UIPopoverPresentationControllerDelegate, UIActionSheetDelegate {
  var photoID: Int = 0  // It set by the collection ciew while perfoming a segue to this controller
  
  let scrollView = UIScrollView()
  let imageView = UIImageView()
  let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
  
  var photoInfo: PhotoInfo?
  
  // MARK: Life-Cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    navigationController?.setNavigationBarHidden(false, animated: true)
    
    setupView()
    
    loadPhoto()
  }
  
  func loadPhoto() {
    // receive a JSON response and uses your new feneric response serializer to create an instance of PhotoInfo out of taht response.
    Alamofire.request(Five100px.Router.PhotoInfo(self.photoID, .Large)).validate().responseObject() {
      // (request, response, data, eerror)
      // The third parameter is explicitly declared as an instance of PhotoInfo, so the generic serializer automatically initializes and rturns an object of this type.
      (_, _, photoInfo: PhotoInfo?, error) in
      
      
      //println("On the main thread? " + (NSThread.currentThread().isMainThread ? "YES" : "NO"))
      
      if error == nil {
        self.photoInfo = photoInfo
        // It's already on main thread
        //dispatch_async(dispatch_get_main_queue()) {
          self.addButtomBar()
          self.title = photoInfo!.name
        //}
      
        // You're not using the router here because you already have the absolute URL of the image, you aren't constructing the URL yourself
        // .validate() 會檢查 statsu code 是否在 200 ~ 299 內，若不在，會拋出error
        Alamofire.request(.GET, photoInfo!.url).validate().responseImage() {
          (_, _, image, error) in
          
          if error == nil && image != nil {
            self.imageView.image = image
            self.imageView.frame = self.centerFrameFromImage(image)
            
            self.spinner.stopAnimating()
            self.centerScrollViewContents()
          }
        }
      } else {
        println("Could not get photo info: \(error!)")
      }
    
    }
  }
  
  func setupView() {
    // view.bounds.origin.y = 0
    spinner.center = CGPoint(x: view.center.x, y: view.center.y - view.bounds.origin.y / 2.0)
    spinner.hidesWhenStopped = true
    spinner.startAnimating()
    view.addSubview(spinner)
    
    // A scroll view is used to allow zomming
    scrollView.frame = view.bounds
    scrollView.delegate = self
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 3.0
    scrollView.zoomScale = 1.0
    view.addSubview(scrollView)
    
    imageView.contentMode = .ScaleAspectFill
    scrollView.addSubview(imageView)
    
    let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: "handleDoubleTap:")
    doubleTapRecognizer.numberOfTapsRequired = 2
    doubleTapRecognizer.numberOfTouchesRequired = 1
    scrollView.addGestureRecognizer(doubleTapRecognizer)
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    
    if photoInfo != nil {
      navigationController?.setToolbarHidden(false, animated: true)
    }
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    //  離開此頁時把 tollbar 隱藏
    navigationController?.setToolbarHidden(true, animated: true)
  }
  
  // MARK: Bottom Bar
  
  func addButtomBar() {
    var items = [UIBarButtonItem]()
    
    let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
    
    items.append(barButtonItemWithImageNamed("hamburger", title: nil, action: "showDetails"))
    
    if photoInfo?.commentsCount > 0 {
      items.append(barButtonItemWithImageNamed("bubble", title: "\(photoInfo?.commentsCount ?? 0)", action: "showComments"))
    }
    
    items.append(flexibleSpace)
    items.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "showActions"))
    items.append(flexibleSpace)
    
    items.append(barButtonItemWithImageNamed("like", title: "\(photoInfo?.votesCount ?? 0)"))
    items.append(barButtonItemWithImageNamed("heart", title: "\(photoInfo?.favoritesCount ?? 0)"))
    
    self.setToolbarItems(items, animated: true)
    navigationController?.setToolbarHidden(false, animated: true)
  }
  
  func showDetails() {
    let photoDetailsViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoDetails") as? PhotoDetailsViewController
    photoDetailsViewController?.modalPresentationStyle = .OverCurrentContext
    photoDetailsViewController?.modalTransitionStyle = .CoverVertical
    photoDetailsViewController?.photoInfo = photoInfo
    
    presentViewController(photoDetailsViewController!, animated: true, completion: nil)
  }
  
  func showComments() {
    let photoCommentsViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoComments") as? PhotoCommentsViewController
    photoCommentsViewController?.modalPresentationStyle = .Popover
    photoCommentsViewController?.modalTransitionStyle = .CoverVertical
    photoCommentsViewController?.photoID = photoID
    photoCommentsViewController?.popoverPresentationController?.delegate = self
    presentViewController(photoCommentsViewController!, animated: true, completion: nil)
  }
  
  // Needed for the Comments Popover
  func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
    return UIModalPresentationStyle.OverCurrentContext
  }
  
  // Nedded for the Comments Popover
  func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
    let navController = UINavigationController(rootViewController: controller.presentedViewController)
    
    return navController
  }
  
  func barButtonItemWithImageNamed(imageName: String?, title: String?, action: Selector? = nil) -> UIBarButtonItem {
    let button = UIButton.buttonWithType(.Custom) as! UIButton
    
    if imageName != nil {
      button.setImage(UIImage(named: imageName!)!.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
    }
    
    if title != nil {
      button.setTitle(title, forState: .Normal)
      button.titleEdgeInsets = UIEdgeInsets(top: 0.0, left: 10.0, bottom: 0.0, right: 0.0)
      
      let font = UIFont.preferredFontForTextStyle(UIFontTextStyleFootnote)
      button.titleLabel?.font = font
    }
    
    let size = button.sizeThatFits(CGSize(width: 90.0, height: 30.0))
    button.frame.size = CGSize(width: min(size.width + 10.0, 60), height: size.height)
    
    if action != nil {
      button.addTarget(self, action: action!, forControlEvents: .TouchUpInside)
    }
    
    let barButton = UIBarButtonItem(customView: button)
    
    return barButton
  }
  
  // MARK: Download Photo
  
  func downloadPhoto() {
    // 1. Request a new PhotoInfo, this time asking for an XLarge size image
    Alamofire.request(Five100px.Router.PhotoInfo(photoInfo!.id, .XLarge)).validate().responseObject() {
      (_, _, photoInfo: PhotoInfo?, error) in
      
      if error == nil && photoInfo != nil {
        let imageURL = photoInfo!.url
        //let jsonDictionary = (JSON as! NSDictionary)
        //let imageURL = jsonDictionary.valueForKeyPath("photo.image_url") as! String
        //let jsonDictionary = (JSON as! [String: AnyObject])
        //let imageURL = jsonDictionary["photo"]["image_url"] as! String
        
        // 2. Get the default location on disk to which to save your file. This will be a subdirectory in the Documents directory of your app. The name of the file on disk will be the same as the name that the server suggets.
        //let destination = Alamofire.Request.suggestedDownloadDestination(directory: .DocumentDirectory, domain: .UserDomainMask)
        // Implemented your own naming logic.
        let destination: (NSURL, NSHTTPURLResponse) -> (NSURL) = {
          (temporaryURL, response) in
          
          if let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
            return directoryURL.URLByAppendingPathComponent("\(self.photoInfo!.id).\(response.suggestedFilename!)")
          }
          
          return temporaryURL
        
        }
      
        // 3. It doesn't need a response handler or a serializer in order to perform an opertaion on the data, as it already knows what to do with it - save it to disk. The destination closure returns the location of the saved image.
        //Alamofire.download(.GET, imageURL, destination)
        
        
        // 4. Use standard UIProgressView to show the progress og downloading a photo. Set it up and add it to the view hierarchy.
        let progressIndicatorView = UIProgressView(frame: CGRect(x: 0.0, y: 80.0, width: self.view.bounds.width, height: 10.0))
        progressIndicatorView.tintColor = UIColor.blueColor()
        self.view.addSubview(progressIndicatorView)
        
        // 5. With Alamofire you can chain .progress(), which takes a closure called periodically with three parameters: bytesRead, totalBytesRead, totalBytesExpectedToRead.
        Alamofire.download(.GET, imageURL, destination).progress {
          (_, totalBytesRead, totalBytesExpectedToRead) in
          
          //println("On the main thread? " + (NSThread.currentThread().isMainThread ? "YES" : "NO"))
          
          // progress handler is no execuate on main queue
          dispatch_async(dispatch_get_main_queue()) {
            // 6. Simply divide toalBytesRead by totalBytesEcpectedToRead and you'll get anumber betoeen 0 and 1 that represents the progress og the download task. This colsure may execute muliple times if the download time isn't nearinstantaneous, each execution gives you a chance to update a progress bar on the screen
            progressIndicatorView.setProgress(Float(totalBytesRead) / Float(totalBytesExpectedToRead), animated: true)
            
            // 7. Once the download is finished, simply remove the progress bar from the view hierarchy.
            if totalBytesRead == totalBytesExpectedToRead {
              progressIndicatorView.removeFromSuperview()
            }
          }
        
        }
        
      }
      
    
    }
  }

  func showActions() {
    let actionSheet = UIActionSheet(title: nil, delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Download Photo")
    actionSheet.showFromToolbar(navigationController?.toolbar)
  }
  
  func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
    if buttonIndex == 1 {
      downloadPhoto()
    }
  }
  
  // MARK: Gesture Recognizers
  
  func handleDoubleTap(recognizer: UITapGestureRecognizer!) {
    let pointInView = recognizer.locationInView(self.imageView)
    self.zoomInZoomOut(pointInView)
  }
  
  // MARK: ScrollView
  
  func centerFrameFromImage(image: UIImage?) -> CGRect {
    if image == nil {
      return CGRectZero
    }
    
    let scaleFactor = scrollView.frame.size.width / image!.size.width
    let newHeight = image!.size.height * scaleFactor
    
    var newImageSize = CGSize(width: scrollView.frame.size.width, height: newHeight)
    
    newImageSize.height = min(scrollView.frame.size.height, newImageSize.height)
    
    let centerFrame = CGRect(x: 0.0, y: scrollView.frame.size.height/2 - newImageSize.height/2, width: newImageSize.width, height: newImageSize.height)
    
    return centerFrame
  }
  
  func scrollViewDidZoom(scrollView: UIScrollView) {
    self.centerScrollViewContents()
  }
  
  func centerScrollViewContents() {
    let boundsSize = scrollView.frame
    var contentsFrame = self.imageView.frame
    

    
    if contentsFrame.size.width < boundsSize.width {
      contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
    } else {
      contentsFrame.origin.x = 0.0
    }
    
    if contentsFrame.size.height < boundsSize.height {
      contentsFrame.origin.y = (boundsSize.height - scrollView.scrollIndicatorInsets.top - scrollView.scrollIndicatorInsets.bottom - contentsFrame.size.height) / 2.0
    } else {
      contentsFrame.origin.y = 0.0
    }
    //println("scrollView: \(scrollView.frame.origin)")
    //println("self.imageView.frame: \(self.imageView.frame)")
    self.imageView.frame = contentsFrame
    //println("contentsFrame: \(contentsFrame)")
    //println("after self.imageView.frame: \(self.imageView.frame)")
  }
  
  func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
    return self.imageView
  }
  
  func zoomInZoomOut(point: CGPoint!) {
    let newZoomScale = self.scrollView.zoomScale > (self.scrollView.maximumZoomScale/2) ? self.scrollView.minimumZoomScale : self.scrollView.maximumZoomScale
    
    let scrollViewSize = self.scrollView.bounds.size
    let width = scrollViewSize.width / newZoomScale
    let height = scrollViewSize.height / newZoomScale
    let x = point.x - (width / 2.0)
    let y = point.y - (height / 2.0)

    let rectToZoom = CGRect(x: x, y: y, width: width, height: height)
    
    self.scrollView.zoomToRect(rectToZoom, animated: true)
    
  }
}
