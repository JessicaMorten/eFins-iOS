//
//  ItemForm.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 4/17/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import Foundation
import Realm

@objc
protocol ItemForm {
    var model: RLMObject? { get set }
    var label: String? { get set }
    var allowEditing:Bool { get set }
}