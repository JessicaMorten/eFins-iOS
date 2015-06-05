//
//  PhotosCollectionViewController.swift
//  eFins-iOS
//
//  Created by CHAD BURT on 4/27/15.
//  Copyright (c) 2015 McClintock Lab. All rights reserved.
//

import UIKit
import AVFoundation
import Realm

class PhotosCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var cameraButton: UIBarButtonItem!
    var activity:Activity!
    let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    let reuseIdentifier = "PhotoCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.title = "Photos"
        // Do any additional setup after loading the view.
        if !self.editing {
            self.navigationItem.rightBarButtonItem = nil
        }
    }


    func takePhoto(sender: AnyObject?) {
        let ipc = UIImagePickerController()
        ipc.delegate = self
        if(UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)) {
            ipc.sourceType = UIImagePickerControllerSourceType.Camera
            self.presentViewController(ipc, animated: true, completion: nil)
        } else {
            alert("Camera Not Available", "Camera is not available on this device", self)
        }
    }
    
    @IBAction func chooseFromLibrary(sender: AnyObject?) {
        let ipc = UIImagePickerController()
        ipc.delegate = self
        ipc.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.presentViewController(ipc, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        let realm = RLMRealm.defaultRealm()
        realm.beginWriteTransaction()
        Photo.create(image) { (photo: Photo) in
            realm.addObject(photo)
            self.activity.photos.addObject(photo)
            self.activity.updatedAt = NSDate()
            realm.commitWriteTransaction()
            picker.dismissViewControllerAnimated(true, completion: nil)
            self.collectionView?.reloadData()
        }
    }
    
    @IBAction func cameraAction(sender: AnyObject) {
        let alert = getAlert()
        alert.popoverPresentationController?.barButtonItem = self.cameraButton
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func getAlert() -> UIAlertController {
        let alert = UIAlertController(title: "Add Photo", message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
        let cameraAction = UIAlertAction(title: "Take Photo", style: .Default) { (action) in
            self.takePhoto(nil)
        }
        alert.addAction(cameraAction)
        let pickAction = UIAlertAction(title: "Choose from Library", style: .Default) { (action) in
            self.chooseFromLibrary(nil)
        }
        alert.addAction(pickAction)
        return alert
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return Int(self.activity.photos.count)
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        let photo = self.activity.photos.objectAtIndex(UInt(indexPath.row)) as! Photo
//        cell.backgroundColor = UIColor.blackColor()
        cell.imageView.image = photo.thumbnailImage
        // Configure the cell
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let photo = self.activity.photos.objectAtIndex(UInt(indexPath.row)) as! Photo
        var size = photo.thumbnailImage.size
        size.width = size.width / 2
        size.height = size.height / 2
        return size
    }
    
    //3
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            return sectionInsets
    }

}
