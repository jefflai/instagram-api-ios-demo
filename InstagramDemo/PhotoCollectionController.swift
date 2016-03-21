//
//  PhotoCollectionController.swift
//  InstagramDemo
//
//  Created by Jeff Lai on 3/20/16.
//  Copyright © 2016 Jeff Lai. All rights reserved.
//

import UIKit
import UICollectionViewLeftAlignedLayout
import AFNetworking

class PhotoCollectionController : UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var accessToken : String?
    var photoUrls : [String]?
    
    convenience init() {
        self.init(collectionViewLayout: UICollectionViewLeftAlignedLayout())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = UIColor.darkGrayColor()
        collectionView?.registerClass(UICollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadSelfUserData()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func loadSelfUserData() {
        makeInstagramApiCall("/users/self/", queryParameters: nil, completionHandler : { [weak self] (response : NSURLResponse, responseObject : AnyObject?, error : NSError?) -> Void in
            if let error = error {
                print(error)
            } else {
                if let strongSelf = self, responseObject = responseObject as? NSDictionary {
                    let userId = responseObject["data"]?["id"] as? String
                    strongSelf.loadRecentPhotoUrls(userId)
                }
            }
        })
    
    }
    
    func loadRecentPhotoUrls(userId : String?) {
        if let userId = userId {
            let queryParameters = ["count" : "20"]
            makeInstagramApiCall("/users/" + userId + "/media/recent/", queryParameters: queryParameters, completionHandler: { [weak self] (response : NSURLResponse, responseObject : AnyObject?, error : NSError?) -> Void in
                if let strongSelf = self, mediaArray = responseObject?["data"] as? NSArray {
                    strongSelf.photoUrls = [String]()
                    for media in mediaArray {
                        if let media = media as? NSDictionary {
                            if let type = media["type"] as? String {
                                if type == "image" {
                                    if let photoUrl = media["images"]?["low_resolution"]??["url"] as? String {
                                        strongSelf.photoUrls?.append(photoUrl)
                                    }
                                }
                            }
                        }
                    }
                    strongSelf.collectionView?.reloadData()
                }
            })
        }
    }
    
    func makeInstagramApiCall(urlPath : String, queryParameters : [String : String]?, completionHandler : ((NSURLResponse, AnyObject?, NSError?) -> Void)?) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let manager = AFURLSessionManager(sessionConfiguration: configuration)
        if let accessToken = accessToken {
            var queryString = "?access_token=" + accessToken
            if let queryParameters = queryParameters {
                for (key, value) in queryParameters {
                    queryString += "&" + key + "=" + value
                }
            }
            if let usersSelfUrl = NSURL(string: "https://api.instagram.com/v1" + urlPath + queryString) {
                let usersSelfRequest = NSURLRequest(URL: usersSelfUrl)
                let usersSelfDataTask = manager.dataTaskWithRequest(usersSelfRequest, completionHandler: completionHandler)
                usersSelfDataTask.resume()
            }
        }
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numPhotos = 0
        if let photoUrls = photoUrls {
            numPhotos = photoUrls.count
        }
        return numPhotos
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath)
    }
    
    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if cell.contentView.subviews.count > 0 {
            for subview in cell.contentView.subviews {
                subview.removeFromSuperview()
            }
        }
        
        let photoCellContents = makePhotoCellContents(collectionView, cellForItemAtIndexPath: indexPath)
        photoCellContents.frame = cell.contentView.bounds
        photoCellContents.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
        cell.contentView.addSubview(photoCellContents)
    }
    
    func makePhotoCellContents(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UIImageView {
        let imageView = UIImageView()
        if let photoUrls = photoUrls {
            let photoUrl = photoUrls[indexPath.row]
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let manager = AFURLSessionManager(sessionConfiguration: configuration)
            if let downloadUrl = NSURL(string: photoUrl) {
                let downloadRequest = NSURLRequest(URL: downloadUrl)
                let downloadTask = manager.downloadTaskWithRequest(downloadRequest, progress: nil,
                    destination: { (targetPath : NSURL, response : NSURLResponse) -> NSURL in
                        let fileManager = NSFileManager.defaultManager()
                        let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                        let pathComponent = response.suggestedFilename
                        return directoryURL.URLByAppendingPathComponent(pathComponent!)
                    }, completionHandler: { [weak imageView] (response : NSURLResponse, fileUrl : NSURL?, error : NSError?) -> Void in
                        dispatch_async(dispatch_get_main_queue(), { [weak imageView, weak fileUrl] () -> Void in
                            if let imageView = imageView, filePath = fileUrl?.path {
                                let image = UIImage(contentsOfFile: filePath)
                                imageView.image = image
                            }
                        })
                })
                downloadTask.resume()
            }
        }
        return imageView
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(floor(collectionView.frame.width * 0.33), floor(collectionView.frame.width * 0.33))
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1.0
    }
    
}
