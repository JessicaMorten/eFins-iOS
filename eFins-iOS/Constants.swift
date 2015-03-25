//
//  Constants.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/11/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation

#if DEBUG_SERVER
//let SERVER_ROOT = "http://localhost:3002/"
let SERVER_ROOT = "http://10.0.1.7:3002/"
#else
let SERVER_ROOT = "https://efins.org/"
#endif

struct Urls {
    static let root = SERVER_ROOT

    // requires email, password
    static let register = "\(root)auth/register"
    static let getToken = "\(root)auth/getToken"

    // requires bearer token
    static let expireToken = "\(root)auth/expireToken"
    static let passwordReset = "\(root)auth/requestPasswordReset"
}

let ADMIN_EMAIL = "support@efins.org"

let locale = NSLocale.currentLocale()

func getDateFormatter() -> NSDateFormatter {
    let formatter = NSDateFormatter()
    formatter.dateFormat = NSDateFormatter.dateFormatFromTemplate("yyyy-MM-dd 'at' HH:mm", options: 0, locale: locale)
    formatter.locale = locale
    return formatter
}

