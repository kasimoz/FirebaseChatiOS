//
//  PhotosViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 6.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit


class PhotosViewController: UICollectionViewController {
    var photos : [String] = []
    var check : [IndexPath] = []
    var documentsURL : URL!
    var longPress : UILongPressGestureRecognizer!
    var selectedIndexPath : IndexPath!
    var push = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellSize = CGSize(width:(self.view.frame.width - 2.0) / 3 , height: (self.view.frame.width - 2.0) / 3)
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical //.horizontal
        layout.itemSize = cellSize
        //layout.sectionInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        layout.minimumLineSpacing = 1.0
        layout.minimumInteritemSpacing = 1.0
        collectionView.setCollectionViewLayout(layout, animated: true)
        
        self.documentsURL = URL.createFolder(folderName: "Photos")
        self.photos = documentsURL?.listFilesFromDownloadsFolder() ?? []
        self.collectionView.reloadData()
        
        self.longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_ :)))
        self.collectionView.addGestureRecognizer(self.longPress)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deleteAction(_:)), name: NSNotification.Name("delete"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("delete"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.deleteAction(_:)), name: NSNotification.Name("delete"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.push {
            self.push = false
            if let cell = self.collectionView.cellForItem(at: self.selectedIndexPath) {
                let localURL = documentsURL!.appendingPathComponent(self.photos[self.selectedIndexPath.row])
                let imageView = cell.viewWithTag(1) as? UIImageView
                imageView?.image = UIImage.init(contentsOfFile: localURL.path)!.thumbImage().square()
            }
        }else {
            NotificationCenter.default.post(name: NSNotification.Name("toolbar"), object: nil, userInfo: ["hidden" : true])
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("delete"), object: nil)
            self.collectionView.removeGestureRecognizer(self.longPress)
        }
    }
    
    @objc func deleteAction(_ notification: NSNotification) {
        self.check.sort(by: { (first: IndexPath, second: IndexPath) -> Bool in
            first.row > second.row
        })
        for i in self.check {
            let fileName = self.photos[i.row]
            self.photos.remove(at: i.row)
            self.collectionView.performBatchUpdates({
                self.collectionView.deleteItems(at: [i])
            }, completion: { result in
                URL.deleteFile(documentPath: self.documentsURL!.appendingPathComponent(fileName).path)
            })
        }
        self.check.removeAll()
        NotificationCenter.default.post(name: NSNotification.Name("toolbar"), object: nil, userInfo: ["hidden" : true])
    }
    
    
    @objc func handleLongPress(_ gesture : UILongPressGestureRecognizer!) {
        if gesture.state != .began {
            return
        }
        let p = gesture.location(in: self.collectionView)
        
        if let indexPath = self.collectionView.indexPathForItem(at: p) {
            // get the cell at indexPath (the one you long pressed)
            //let cell = self.collectionView.cellForItem(at: indexPath)
            if let index = self.check.firstIndex(of: indexPath) {
                self.check.remove(at: index)
            }else{
                self.check.append(indexPath)
            }
            self.collectionView.reloadItems(at: [indexPath])
            NotificationCenter.default.post(name: NSNotification.Name("toolbar"), object: nil, userInfo: ["hidden" : self.check.isEmpty])
        } else {
            print("couldn't find index path")
        }
    }
    
    
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return self.photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        let imageView = cell.viewWithTag(1) as? UIImageView
        let checkmark = cell.viewWithTag(2) as? UIImageView
        let localURL = documentsURL!.appendingPathComponent(self.photos[indexPath.row])
        imageView?.image = UIImage.init(contentsOfFile: localURL.path)!.thumbImage().square()
        checkmark?.isHidden = !(self.check.firstIndex(of: indexPath) ?? -1 > -1)
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.check.isEmpty {
            self.push = true
            self.selectedIndexPath = indexPath
            if let cell = self.collectionView.cellForItem(at: indexPath) {
                let localURL = documentsURL!.appendingPathComponent(self.photos[indexPath.row])
                let imageView = cell.viewWithTag(1) as? UIImageView
                imageView?.image = UIImage.init(contentsOfFile: localURL.path)
            }
            CustomDelegate.shared.previewImage(collectionView: self.collectionView, selectedIndexPath: selectedIndexPath, photo: self.photos[indexPath.row])
        }else {
            if let index = self.check.firstIndex(of: indexPath) {
                self.check.remove(at: index)
            }else{
                self.check.append(indexPath)
            }
            self.collectionView.reloadItems(at: [indexPath])
            NotificationCenter.default.post(name: NSNotification.Name("toolbar"), object: nil, userInfo: ["hidden" : self.check.isEmpty])
        }
    }
    
    
    
    // MARK: UICollectionViewDelegate
    
    /*
     // Uncomment this method to specify if the specified item should be highlighted during tracking
     override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment this method to specify if the specified item should be selected
     override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
     return true
     }
     */
    
    /*
     // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
     override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
     return false
     }
     
     override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
     
     }
     */
    
}


