//
//  RelationTableViewCell.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 3/31/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import Realm

class RelationTableViewCell: UITableViewCell {
    
    var secondaryProperty: RLMProperty?
    @IBInspectable var modelLabelProperty: String = "name"
    @IBInspectable var modelFormClass: String?
    var property:RLMProperty?
    var model:RLMObject?
    
    var allowEditing = true
    
    var oneToMany:Bool {
        get {
            return property?.type == RLMPropertyType.Array
        }
    }
    
    var propertyValue:AnyObject? {
        get {
            if let prop = property {
                return model?.valueForKey(prop.name)
            } else {
                return nil
            }
        }
    }
    
    var secondaryPropertyValue:AnyObject? {
        get {
            if let prop = secondaryProperty {
                return model?.valueForKey(prop.name)
            } else {
                return nil
            }
        }
    }
    
    var allValues:[RLMObject] {
        get {
            var items = [RLMObject]()
            println(propertyValue)
            if propertyValue != nil {
                items = items + rlmArrayToNSArray(propertyValue as! RLMArray)
            }
            if secondaryPropertyValue != nil {
                items = items + rlmArrayToNSArray(secondaryPropertyValue as! RLMArray)
            }
            return items
        }
    }
    
    var value:RLMObject? {
        get {
            if propertyValue != nil {
                return propertyValue as! RLMObject
            } else if secondaryPropertyValue != nil {
                return secondaryPropertyValue as! RLMObject
            } else {
                return nil
            }
        }
    }


    var hasValue:Bool {
        get {
            let val: AnyObject? = propertyValue
            if val != nil {
                if self.oneToMany {
                    return (val as! RLMArray).count > 0
                } else {
                    return val != nil
                }
            }
            return false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setup(model: RLMObject, allowEditing: Bool, property: String, secondaryProperty: String?) {
        self.model = model
        self.allowEditing = allowEditing
        self.property = getRealmModelProperty(model.objectSchema.className, property)
        if let prop = secondaryProperty {
            self.secondaryProperty = getRealmModelProperty(model.objectSchema.className, prop)
        }
        updateValues()
    }
    
    func updateValues() {
        if model != nil {
            if oneToMany {
                self.detailTextLabel?.text = "\(allValues.count)"
                self.updateRecentValuesCounts()
                if allValues.count < 1 && !allowEditing {
                    self.accessoryType = UITableViewCellAccessoryType.None
                } else {
                    self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                }
            } else {
                if let object: AnyObject = propertyValue {
                    self.detailTextLabel?.text = "\(object.valueForKey(modelLabelProperty))"
                } else {
                    self.detailTextLabel?.text = "None"
                }
                if !allowEditing {
                    self.accessoryType = UITableViewCellAccessoryType.None
                }
            }
        } else {
            self.detailTextLabel?.text = " "
        }
    }
    
    func updateRecentValuesCounts() {
        if model != nil {
            if oneToMany {
                let array:RLMArray = propertyValue as! RLMArray
                var i = 0
                while i < Int(array.count) {
                    let item = array.objectAtIndex(UInt(i)) as! RLMObject?
                    RecentValues.increment(item!, model: self.model!, property: self.property!)
                    i++
                }
                if secondaryProperty != nil {
                    let array:RLMArray = secondaryPropertyValue as! RLMArray
                    var i = 0
                    while i < Int(array.count) {
                        let item = array.objectAtIndex(UInt(i)) as! RLMObject?
                        RecentValues.increment(item!, model: self.model!, property: self.secondaryProperty!)
                        i++
                    }
                }
            } else {
                if let item = propertyValue as? RLMObject {
                    RecentValues.increment(item, model: self.model!, property: self.property!)
                }
                if secondaryProperty != nil {
                    if let item = secondaryPropertyValue as? RLMObject {
                        RecentValues.increment(item, model: self.model!, property: self.secondaryProperty!)
                    }
                }
            }
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        if selected {
            if allowEditing || hasValue {
                let storyboard = UIStoryboard(name: "OneToMany", bundle: nil)
                let destination = storyboard.instantiateInitialViewController() as! OneToManyTableViewController
                let table:UITableView = self.superview?.superview as! UITableView
                let controller = table.dataSource as! UITableViewController
                destination.title = self.textLabel?.text
                destination.model = model
                destination.modelFormClass = modelFormClass
                destination.modelLabelProperty = modelLabelProperty
                destination.property = property
                destination.secondaryProperty = secondaryProperty
                destination.entryFieldName = self.textLabel?.text
                destination.cell = self
                destination.allowEditing = allowEditing
                controller.navigationController?.pushViewController(destination, animated: true)
            }
        }
        super.setSelected(selected, animated: animated)
    }

}
