//
//  MediaViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 6.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit

class MediaViewController: UIViewController, MediaDelegate {
    func previewVideo(collectionView: UICollectionView, selectedIndexPath: IndexPath, video: String) {
        self.selectedIndexPath = selectedIndexPath
        self.collectionView = collectionView
        self.video = video
        self.performSegue(withIdentifier: "video", sender: nil)
    }
    
    func previewImage(collectionView: UICollectionView, selectedIndexPath: IndexPath, photo: String) {
        self.selectedIndexPath = selectedIndexPath
        self.collectionView = collectionView
        self.photo = photo
        self.performSegue(withIdentifier: "image", sender: nil)
    }
    
    @IBOutlet weak var toolbar: UIToolbar!
    var currentViewController: UIViewController?
    var selectedIndexPath : IndexPath!
    var collectionView : UICollectionView!
    var photo: String = ""
    var video: String = ""
    @IBOutlet weak var containerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        CustomDelegate.shared.setMediaDelegate(td: self)
        NotificationCenter.default.addObserver(self, selector: #selector(self.toolbarVisible(_:)), name: NSNotification.Name("toolbar"), object: nil)
        self.performSegue(withIdentifier: "PhotosViewController", sender: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("toolbar"), object: nil)
    }
    
    @IBAction func segmentedControl(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            self.performSegue(withIdentifier: "PhotosViewController", sender: nil)
            break
        case 1:
            self.performSegue(withIdentifier: "VideosViewController", sender: nil)
            break
        case 2:
            self.performSegue(withIdentifier: "AudiosViewController", sender: nil)
            break
        default:
            break
        }
    }
    
    @objc func toolbarVisible(_ notification: NSNotification){
        if let hidden = notification.userInfo?["hidden"] as? Bool {
            self.toolbar.isHidden = hidden
        }else{
            self.toolbar.isHidden = true
        }
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        NotificationCenter.default.post(name: NSNotification.Name("delete"), object: nil, userInfo: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ImageViewController {
            if let indexPath = self.selectedIndexPath{
                if let cell = self.collectionView.cellForItem(at: indexPath) {
                    vc.selectedImage = self.photo
                    vc.image = (cell.viewWithTag(1) as! UIImageView).image
                }
            }
        }else if let vc = segue.destination as? VideoViewController {
            if let indexPath = self.selectedIndexPath{
                if let cell = self.collectionView.cellForItem(at: indexPath) {
                    vc.videoName = self.video
                    vc.videoThumb = (cell.viewWithTag(1) as! UIImageView).image
                }
            }
        }
    }
}

extension MediaViewController: ZoomingViewController{
    func zoomingImageView(for transition: ZoomTransitioningDelegate) -> UIImageView? {
        if let indexPath = self.selectedIndexPath{
            if let cell = self.collectionView.cellForItem(at: indexPath) {
                return (cell.viewWithTag(1) as! UIImageView)
            }
        }
        return nil
    }
    
    func zoomingBackgroundView(for transition: ZoomTransitioningDelegate) -> UIView? {
        return nil
    }
    
    func zoomingType(for transition: ZoomTransitioningDelegate) -> Constants.SegueType? {
        return .imageVideo
    }
    
    
}


class CustomDelegate {
    static let shared = CustomDelegate()
    
    var mediaDelegate : MediaDelegate! = nil
    
    func setMediaDelegate(td : MediaDelegate){
        self.mediaDelegate = td
    }
    
    func removeMediaDelegate(){
        self.mediaDelegate = nil
    }
    
    func previewImage(collectionView :UICollectionView, selectedIndexPath: IndexPath, photo : String){
        if self.mediaDelegate != nil {
            self.mediaDelegate.previewImage(collectionView: collectionView, selectedIndexPath: selectedIndexPath, photo: photo)
        }
    }
    
    func previewVideo(collectionView :UICollectionView, selectedIndexPath: IndexPath, video : String){
        if self.mediaDelegate != nil {
            self.mediaDelegate.previewVideo(collectionView: collectionView, selectedIndexPath: selectedIndexPath, video: video)
        }
    }
}


protocol MediaDelegate{
    func previewImage(collectionView :UICollectionView, selectedIndexPath: IndexPath, photo : String)
    
    func previewVideo(collectionView :UICollectionView, selectedIndexPath: IndexPath, video : String)
}
