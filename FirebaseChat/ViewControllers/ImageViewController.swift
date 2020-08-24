//
//  ImageViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 26.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage


class ImageViewController: UIViewController {
    
    
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var detailImageView: UIImageView!
    
    var selectedImage: String!
    var image: UIImage?
    var toolbarHidden = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailImageView.image = self.image
        if let imageToLoad = selectedImage {
            let ref = Storage.storage().reference().child("images")
            let indicator = UIActivityIndicatorView()
            ref.loadPhoto(indicator: indicator, fileName: imageToLoad, completion: { result in
                let documentsURL = URL.createFolder(folderName: "Photos")
                let localURL = documentsURL!.appendingPathComponent(result)
                self.detailImageView.image = UIImage.init(contentsOfFile: localURL.path)!
            })
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.toolbar.isHidden = self.toolbarHidden
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.toolbar.isHidden = true
    }
    
    @IBAction func shareImage(_ sender: Any) {
        let image = self.detailImageView.image
        let imageShare = [ image! ]
        let activityViewController = UIActivityViewController(activityItems: imageShare , applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.setValue("Image", forKey: "subject")
        self.present(activityViewController, animated: true, completion: nil)
    }
}

extension ImageViewController: ZoomingViewController{
    func zoomingImageView(for transition: ZoomTransitioningDelegate) -> UIImageView? {
        return detailImageView
    }
    
    func zoomingBackgroundView(for transition: ZoomTransitioningDelegate) -> UIView? {
        return nil
    }
    
    func zoomingType(for transition: ZoomTransitioningDelegate) -> Constants.SegueType? {
        return nil
    }
}


