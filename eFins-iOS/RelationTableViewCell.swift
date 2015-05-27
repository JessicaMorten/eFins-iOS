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
    var propertyName:String?
    var propertyClassName:String?
    var propertyType:RLMPropertyType?
    var model:RLMObject?
    var label:String?
    var skipSearch = false
    var reversedRelation = false
    
    var FuckFuckFuck = false
    
    var allowEditing = true
    
    var entryFieldName:String {
        get {
            if let l = self.label {
                return l
            } else {
                return self.textLabel!.text!
            }
        }
    }
    
    var oneToMany:Bool {
        get {
            return propertyType == RLMPropertyType.Array
        }
    }
    
    var propertyValue:AnyObject? {
        get {
            if let propName = propertyName {
                return model?.valueForKey(propName)
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
    
    func setCustomForm(board:UIStoryboard, identifier: String?) {
        self.modelFormStoryboard = board
        self.modelFormId = identifier
        updateValues()
    }
    
    func setup(model: RLMObject, allowEditing: Bool, property: String?, secondaryProperty: String?) {
        self.model = model
        self.allowEditing = allowEditing
        if property != nil {
            let prop = getRealmModelProperty(model.objectSchema.className, property!)
            self.propertyName = prop.name
            self.propertyType = prop.type
            self.propertyClassName = prop.objectClassName
        }
        if let prop = secondaryProperty {
            self.secondaryProperty = getRealmModelProperty(model.objectSchema.className, prop)
        }
        updateValues()
    }
    
    func updateValues() {
        if model != nil {
            if oneToMany {
                self.detailTextLabel?.text = "\(allValues.count)"
            } else {
                if let object: AnyObject = propertyValue {
                    self.detailTextLabel?.text = "\(object.valueForKey(modelLabelProperty)!)"
                } else {
                    self.detailTextLabel?.text = "None"
                }
            }
        } else {
            self.detailTextLabel?.text = " "
        }
        updateAccessoryType()
    }
    
    func updateAccessoryType() {
        if model != nil {
            let showDetails = self.modelFormStoryboard != nil
            if oneToMany {
                if (propertyValue as! RLMArray).count > 0 {
                    self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                } else {
                    self.accessoryType = UITableViewCellAccessoryType.None
                }
            } else {
                if self.modelFormStoryboard != nil && propertyValue != nil {
                    if allowEditing {
                        self.accessoryType = UITableViewCellAccessoryType.DetailDisclosureButton
                    } else {
                        self.accessoryType = UITableViewCellAccessoryType.DetailButton
                    }
                } else {
                    if allowEditing {
                        self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
                    } else {
                        self.accessoryType = UITableViewCellAccessoryType.None
                    }
                }
            }
        } else {
            self.accessoryType = UITableViewCellAccessoryType.None
        }
    }
    
    func updateRecentValuesCounts() {
        if model != nil {
            if oneToMany {
                let array:RLMArray = propertyValue as! RLMArray
                var i = 0
                while i < Int(array.count) {
                    let item = array.objectAtIndex(UInt(i)) as! RLMObject?
                    RecentValues.increment(item!, model: self.model!, propertyClassName: self.propertyClassName!, propertyName: self.propertyName!)
                    i++
                }
                if secondaryProperty != nil {
                    let array:RLMArray = secondaryPropertyValue as! RLMArray
                    var i = 0
                    while i < Int(array.count) {
                        let item = array.objectAtIndex(UInt(i)) as! RLMObject?
                        RecentValues.increment(item!, model: self.model!, propertyClassName: self.secondaryProperty!.objectClassName!, propertyName: self.secondaryProperty!.name)
                        i++
                    }
                }
            } else {
                if let item = propertyValue as? RLMObject {
                    RecentValues.increment(item, model: self.model!, propertyClassName: self.propertyClassName!, propertyName: self.propertyName!)
                }
                if secondaryProperty != nil {
                    if let item = secondaryPropertyValue as? RLMObject {
                        RecentValues.increment(item, model: self.model!, propertyClassName: self.secondaryProperty!.objectClassName, propertyName: self.secondaryProperty!.name)
                    }
                }
            }
        }
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        // Oh boy. FuckFuckFuck keeps track of whether the picker for this tablecell has been "opened".
        // Before keeping track of this, nested RelationTableViewCells would trigger setSelected, so the segue
        // to open a new picker would occur twice. I chose this name because I'm angry, and future maintainers
        // should treat it like radioactive waste
        if selected && FuckFuckFuck == false {
            if allowEditing || hasValue {
                let storyboard = UIStoryboard(name: "OneToMany", bundle: nil)
                if oneToMany {
                    let destination = storyboard.instantiateInitialViewController() as! OneToManyTableViewController
                    let table:UITableView = self.superview?.superview as! UITableView
                    let controller = table.dataSource as! UITableViewController
                    destination.title = self.textLabel?.text
                    destination.model = model
                    destination.modelFormId = modelFormId
                    destination.modelFormStoryboard = self.modelFormStoryboard
                    destination.modelLabelProperty = modelLabelProperty
                    destination.propertyName = propertyName
                    destination.propertyClassName = propertyClassName
                    destination.secondaryProperty = secondaryProperty
                    destination.entryFieldName = self.entryFieldName
                    destination.cell = self
                    destination.allowEditing = allowEditing
                    destination.skipSearch = skipSearch
                    destination.reversed = reversedRelation
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
                        destination.propertyName = propertyName
                        destination.propertyClassName = propertyClassName
                        destination.secondaryProperty = secondaryProperty
                        destination.entryFieldName = self.entryFieldName
                        destination.cell = self
                        destination.skipSearch = skipSearch
                        destination.reversed = reversedRelation
                        //                    destination.allowEditing = allowEditing
                        controller.navigationController?.pushViewController(destination, animated: true)
                    }
                }
                FuckFuckFuck = true
            }
        } else {
            FuckFuckFuck = false
        }
        super.setSelected(selected, animated: animated)
    }
    
    func unwindOneToOnePicker(sender: PickerTableViewController) {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        FuckFuckFuck = false
        let selection = sender.selection!
        // Determine appropriate property (primary or secondary property)
        if propertyClassName == selection.objectSchema.className {
            model?.setValue(sender.selection!, forKey: propertyName!)
        } else {
            model?.setValue(sender.selection!, forKey: secondaryProperty!.name)
        }
        // save Model
        // reload table data
        self.updateValues()
        realm.commitWriteTransaction()
    }

    func displayDetails(table: UITableViewController) {
        if self.modelFormStoryboard != nil {
            let form = self.modelFormStoryboard!.instantiateViewControllerWithIdentifier(self.modelFormId!) as! UIViewController
            if let l = self.label {
                (form as! ItemForm).label = l
            } else {
                (form as! ItemForm).label = self.textLabel?.text
            }
            (form as! ItemForm).model = propertyValue as! RLMObject
            (form as! ItemForm).allowEditing = false
            table.navigationController?.pushViewController(form, animated: true)
        }
    }
    
    

}
