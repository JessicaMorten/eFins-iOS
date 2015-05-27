//
//  NSBundle+Extension.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 5/27/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation

extension NSBundle {
    
    class var applicationVersionNumber: String? {
        return NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    class var applicationBuildNumber: String? {
        return NSBundle.mainBundle().infoDictionary?["CFBundleVersion"] as? String
    }
    
}