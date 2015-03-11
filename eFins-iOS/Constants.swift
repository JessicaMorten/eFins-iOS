//
//  Constants.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation

#if DEBUG_SERVER
let SERVER_ROOT = "http://localhost:3002/"
#else
let SERVER_ROOT = "https://efins.org/"
#endif

struct Urls {
    static let root = SERVER_ROOT

    // requires email, password
    static let register = "\(root)register"
    static let getToken = "\(root)getToken"

    // requires bearer token
    static let expireToken = "\(root)expireToken"
    static let passwordReset = "\(root)requestPasswordReset"
}



