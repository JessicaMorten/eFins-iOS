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
}

