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

let MAX_THUMBNAIL_SIZE = 640

class Photo: EfinsModel {
    dynamic var originalUrl = ""
    dynamic var latitude = 0
    dynamic var longitude = 0
    dynamic var lowResolution = NSData()
    dynamic var originalBlob = NSData()
    
    var activity: [Activity] {
        return linkingObjectsOfClass("Activity", forProperty: "photos") as! [Activity]
    }

    var thumbnailImage:UIImage {
        get {
            return UIImage(data: self.lowResolution)!
        }
    }
    
    var image:UIImage {
        get {
            return UIImage(data: self.originalBlob)!
        }
    }


    func setImage(image:UIImage) {
        // store original
        self.originalBlob = UIImageJPEGRepresentation(image, 0.8)
        
        // make thumbnail
        if let imageSource = CGImageSourceCreateWithData(self.originalBlob, nil) {
            let options:[NSObject:AnyObject] = [
                kCGImageSourceThumbnailMaxPixelSize: MAX_THUMBNAIL_SIZE,
                kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
                kCGImageSourceCreateThumbnailWithTransform: true
            ]
            
            let scaledImage = UIImage(CGImage: CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options))
            // store thumbnail
            self.lowResolution = UIImageJPEGRepresentation(scaledImage, 0.6)
        }
    }
    
    override func doNotPush() -> [String] {
        return ["originalBlob"]
    }
    
    override class func getSpecialDataPropertyHandler(property: String) -> ((String) -> NSData)? {
        if property == "lowResolution" {
            return { (data: String) -> NSData in
                let base64data = NSData(base64EncodedString: data, options: NSDataBase64DecodingOptions() )
                let image = UIImage(data: base64data!)
                return UIImageJPEGRepresentation(image, 1.0)
            }
        } else if property == "originalBlob" {
            // Just fill this one in with empty data for now
            return {(data: String) -> NSData in
                return NSData()
            }
        }
        return nil
    }

}

