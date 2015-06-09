//
//  Photo.swift
//  eFins-iOS
//
//  Created by Todd Bryan on 3/24/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm
import AVFoundation
import ImageIO
import AWSS3

let MAX_THUMBNAIL_SIZE = 960

class Photo: EfinsModel {
    dynamic var s3key = NSUUID.init().UUIDString
    dynamic var bucket = PHOTOS_BUCKET
    dynamic var hasLocalCopy = false
    dynamic var uploaded = false
    dynamic var uploadedThumbnail = false
    dynamic var signedOriginalUploadUrl = ""
    dynamic var signedThumbnailUploadUrl = ""
    
    override func doNotPush() -> [String] {
        return ["hasLocalCopy", "signedOriginalUploadUrl", "signedThumbnailUploadUrl"]
    }
    
    static func create(image:UIImage, next:(Photo) -> ()) {
        let photo = Photo()
        photo.setImage(image)
        photo.s3key = photo.localId
        photo.hasLocalCopy = true
        photo.createSignedUrls { (success:Bool) in
            next(photo)
        }
    }
    
    var activity: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "photos") as! [Activity]
    }
    
    var thumbnailImage:UIImage {
        get {
            if let data = self.thumbnailImageData {
                if let image = UIImage(data: data) {
                    return image
                }
            }
            return UIImage(named: "not-synced")!
        }
    }
    
    var image:UIImage {
        get {
            if let data = self.originalImageData {
                if let image = UIImage(data: data) {
                    return image
                }
            }
            return UIImage(named: "not-synced")!
        }
    }
    
    var originalImageData:NSData? {
        get {
            if let url = self.getOriginalFilePath() {
                if let path = url.path {
                    let filemgr = NSFileManager.defaultManager()
                    if filemgr.fileExistsAtPath(path) {
                        return NSData(contentsOfFile: path)
                    }
                }
            }
            return nil
        }
    }
    
    var thumbnailImageData:NSData? {
        get {
            if let url = self.getThumbnailFilePath() {
                if let path = url.path {
                    let filemgr = NSFileManager.defaultManager()
                    if filemgr.fileExistsAtPath(path) {
                        return NSData(contentsOfFile: path)
                    }
                }
            }
            return nil
        }
    }
    
    
    func setImage(image:UIImage) {
        // store original
        let originalBlob = UIImageJPEGRepresentation(image, 0.8)
        originalBlob.writeToFile(getOriginalFilePath()!.path!, atomically: true)
        
        // make thumbnail
        if let imageSource = CGImageSourceCreateWithData(originalBlob, nil) {
            let options:[NSObject:AnyObject] = [
                kCGImageSourceThumbnailMaxPixelSize: MAX_THUMBNAIL_SIZE,
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            
            let scaledImage = UIImage(CGImage: CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options))
            // store thumbnail
            let lowResolution = UIImageJPEGRepresentation(scaledImage, 0.6)
            lowResolution.writeToFile(getThumbnailFilePath()!.path!, atomically: true)
        }
    }
    
    func getOriginalFilePath() -> NSURL? {
        let cache = NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.CachesDirectory, inDomain: NSSearchPathDomainMask.AllDomainsMask, appropriateForURL: nil, create: false, error: nil)
        return cache?.URLByAppendingPathComponent("\(self.localId)")
    }
    
    func getThumbnailFilePath() -> NSURL? {
        let cache = NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.CachesDirectory, inDomain: NSSearchPathDomainMask.AllDomainsMask, appropriateForURL: nil, create: false, error: nil)
        return cache?.URLByAppendingPathComponent("\(self.localId)-thumb")
    }
    
    override class func getSpecialDataPropertyHandler(property: String) -> ((String) -> NSData)? {
        if property == "lowResolution" {
            //            return { (data: String) -> NSData in
            //                let base64data = NSData(base64EncodedString: data, options: NSDataBase64DecodingOptions() )
            //                let image = UIImage(data: base64data!)
            //                return UIImageJPEGRepresentation(image, 1.0)
            //            }
            // Just fill this one in with empty data for now
            return {(data: String) -> NSData in
                return NSData()
            }
            
        } else if property == "originalBlob" {
            // Just fill this one in with empty data for now
            return {(data: String) -> NSData in
                return NSData()
            }
        }
        return nil
    }
    
    func createSignedUrls(next:(Bool) -> ()) {
        let r = AWSS3GetPreSignedURLRequest()
        r.bucket = self.bucket
        r.key = self.localId
        r.HTTPMethod = AWSHTTPMethod.PUT
        r.expires = NSDate(timeIntervalSinceNow: 31556952 * 2) // one year * 2
        r.contentType = "image/jpg"
        AWSS3PreSignedURLBuilder.defaultS3PreSignedURLBuilder().getPreSignedURL(r).continueWithBlock { (task:BFTask!) -> (AnyObject!) in
            if task.error != nil {
                next(false)
            } else {
                if let presignedURL = task.result as? NSURL {
                    println("upload presignedURL is: \n%@", presignedURL)
                    self.signedOriginalUploadUrl = presignedURL.URLString
                    r.key = "\(self.localId)-thumb"
                    AWSS3PreSignedURLBuilder.defaultS3PreSignedURLBuilder().getPreSignedURL(r).continueWithBlock { (task:BFTask!) -> (AnyObject!) in
                        if task.error != nil {
                            next(false)
                        } else {
                            if let presignedURL = task.result as? NSURL {
                                println("thumbnail presignedURL is: \n%@", presignedURL)
                                self.signedThumbnailUploadUrl = presignedURL.URLString
                                next(true)
                            } else {
                                next(false)
                            }
                        }
                        return nil
                    }
                } else {
                    next(false)
                }
            }
            return nil
        }
    }
    
}
