//
//  VideoViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 29.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import FirebaseStorage

class VideoViewController: UIViewController, VideoViewDelegate {
    
    var videoThumb : UIImage!
    var videoName = ""
    @IBOutlet weak var playButton: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var videoView: VideoView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.videoImageView.image = videoThumb
    }
    
    @IBAction func playPauseAction(_ sender: UIBarButtonItem) {
        var items = self.toolbar.items
        if self.videoView.isPlaying() {
            let item = UIBarButtonItem.init(barButtonSystemItem: .play, target: self, action: #selector(playPauseAction(_:)))
            item.tintColor = Constants.blue
            items![2] = item
            self.videoView.pause()
        }else{
            let item = UIBarButtonItem.init(barButtonSystemItem: .pause, target: self, action: #selector(playPauseAction(_:)))
            item.tintColor = Constants.blue
            items![2] = item
            self.videoView.play()
        }
        self.toolbar.setItems(items, animated: true)
    }
    
    func reachTheEndOfTheVideo() {
        var items = self.toolbar.items
        let item = UIBarButtonItem.init(barButtonSystemItem: .play, target: self, action: #selector(playPauseAction(_:)))
        item.tintColor = Constants.blue
        items![2] = item
        self.videoView.stop()
        self.toolbar.setItems(items, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.toolbar.isHidden = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let documentsURL = URL.createFolder(folderName: "Videos")
        let fileUrl = documentsURL?.appendingPathComponent(self.videoName)
        self.videoView.configure(url: fileUrl!.path)
        self.videoView.delegate = self
        self.videoView.play()
        self.playButton.isEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.videoView.isPlaying() {
            self.videoView.stop()
        }
        self.toolbar.isHidden = true
        self.videoView.isHidden = true
    }
    
    @IBAction func shareVideo(_ sender: Any) {
        let documentsURL = URL.createFolder(folderName: "Videos")
        let fileUrl = documentsURL?.appendingPathComponent(self.videoName)
        let video = URL.init(string: "file://" + fileUrl!.path)
        let videoShare = [ video!]
        let activityViewController = UIActivityViewController(activityItems: videoShare , applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.setValue("Video", forKey: "subject")
        self.present(activityViewController, animated: true, completion: nil)
    }
}

extension VideoViewController: ZoomingViewController{
    func zoomingImageView(for transition: ZoomTransitioningDelegate) -> UIImageView? {
        return videoImageView
    }
    
    func zoomingBackgroundView(for transition: ZoomTransitioningDelegate) -> UIView? {
        return nil
    }
    
    func zoomingType(for transition: ZoomTransitioningDelegate) -> Constants.SegueType? {
        return .imageVideo
    }
}
