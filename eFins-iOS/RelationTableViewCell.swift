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
    var modelFormId: String?
    var modelFormStoryboard: UIStoryboard?
    var property:RLMProperty?
    var model:RLMObject?
    var 🎵FuckFuckFuck🎵 = false
    
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
    
    func setCustomForm(storyboard:UIStoryboard, identifier: String) {
        self.modelFormStoryboard = storyboard
        self.modelFormId = identifier
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
                if allValues.count < 1 && !allowEditing {
                    self.accessoryType = UITableViewCellAccessoryType.None
                } else {
                    self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                }
            } else {
                if let object: AnyObject = propertyValue {
                    self.detailTextLabel?.text = "\(object.valueForKey(modelLabelProperty)!)"
                    if self.modelFormId != nil {
                        if allowEditing {
                            self.accessoryType = UITableViewCellAccessoryType.DetailDisclosureButton
                        } else {
                            self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                        }
                    } else {
                        self.accessoryType = UITableViewCellAccessoryType.None
                    }
                } else {
                    self.detailTextLabel?.text = "None"
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
        // Oh boy. 🎵FuckFuckFuck🎵 keeps track of whether the picker for this tablecell has been "opened".
        // Before keeping track of this, nested RelationTableViewCells would trigger setSelected, so the segue
        // to open a new picker would occur twice. I chose this name because I'm angry, and future maintainers
        // should treat it like radioactive waste
        if selected && 🎵FuckFuckFuck🎵 == false {
            if allowEditing || hasValue {
                let storyboard = UIStoryboard(name: "OneToMany", bundle: nil)
                if oneToMany {
                    let destination = storyboard.instantiateInitialViewController() as! OneToManyTableViewController
                    let table:UITableView = self.superview?.superview as! UITableView
                    let controller = table.dataSource as! UITableViewController
                    destination.title = self.textLabel?.text
                    destination.model = model
                    destination.modelFormId = modelFormId
                    destination.modelFormStoryboard = storyboard
                    destination.modelLabelProperty = modelLabelProperty
                    destination.property = property
                    destination.secondaryProperty = secondaryProperty
                    destination.entryFieldName = self.textLabel?.text
                    destination.cell = self
                    destination.allowEditing = allowEditing
                    controller.navigationController?.pushViewController(destination, animated: true)
                } else {
                    if allowEditing {
                        let destination = storyboard.instantiateViewControllerWithIdentifier("Picker") as! PickerTableViewController
                        let table:UITableView = self.superview?.superview as! UITableView
                        let controller = table.dataSource as! UITableViewController
                        destination.title = self.textLabel?.text
                        destination.model = model
                        destination.modelFormId = self.modelFormId
                        destination.modelFormStoryboard = self.modelFormStoryboard
                        //                    destination.modelFormClass = modelFormClass
                        destination.labelProperty = modelLabelProperty
                        destination.property = property
                        destination.secondaryProperty = secondaryProperty
                        destination.entryFieldName = self.textLabel?.text
                        destination.cell = self
                        //                    destination.allowEditing = allowEditing
                        controller.navigationController?.pushViewController(destination, animated: true)
                    }
                }
                🎵FuckFuckFuck🎵 = true
            }
        } else {
            🎵FuckFuckFuck🎵 = false
        }
        super.setSelected(selected, animated: animated)
    }
    
    func unwindOneToOnePicker(sender: PickerTableViewController) {
        🎵FuckFuckFuck🎵 = false
        let selection = sender.selection!
        // Determine appropriate property (primary or secondary property)
        var prop:RLMArray
        if property?.objectClassName == selection.objectSchema.className {
            model?.setValue(sender.selection!, forKey: property!.name)
        } else {
            model?.setValue(sender.selection!, forKey: secondaryProperty!.name)
        }
        // save Model
        // reload table data
        self.updateValues()
    }


}
