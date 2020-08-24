//
//  ImageOrVideoPreviewViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 23.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit

class ImageOrVideoPreviewViewController: UIViewController , VideoViewDelegate{
    
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var playButton: UIButton!
    var attachmentFileName : String = ""
    var attachmentImage : UIImage!
    var attachmentVideoUrl : URL!
    var uploadFile = false
    var isMovie = false
    var isCopy = false
    var fileUrl : URL!
    var isPlay = true
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var videoView: VideoView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let documentsURL = URL.createFolder(folderName: self.isMovie ? "Videos" : "Photos")
        self.fileUrl = documentsURL?.appendingPathComponent(self.attachmentFileName)
        
        // self.imageView.image = UIImage(contentsOfFile: imageUrl!.path)
        if self.isMovie {
            self.videoView.configure(url: self.attachmentVideoUrl.path)
            self.videoView.delegate = self
            self.playButton.isHidden = false
        }else{
            self.imageView.image = self.attachmentImage
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationMessage(_:)), name: NSNotification.Name("notification"), object: nil)
        
    }
    
    @objc func notificationMessage(_ notification: NSNotification) {
        if let _ = notification.userInfo?["sender"] as? String {
            if let _ = notification.userInfo?["chatUID"] as? String {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func reachTheEndOfTheVideo() {
        self.isPlay = true
        self.videoView.stop()
        self.playButton.setImage(UIImage.init(systemName: "play.circle"), for: .normal)
    }
    
    @IBAction func playAction(_ sender: UIButton) {
        if self.isPlay {
            self.isPlay = false
            self.videoView.play()
            self.playButton.setImage(UIImage.init(systemName: "pause.circle"), for: .normal)
        }else{
            self.isPlay = true
            self.videoView.pause()
            self.playButton.setImage(UIImage.init(systemName: "play.circle"), for: .normal)
        }
    }
    
    @IBAction func sendAction(_ sender: Any) {
        self.uploadFile = true
        var imageData : [String: Any] = [:]
        imageData["filePath"] = self.fileUrl.path
        NotificationCenter.default.post(name: Notification.Name("uploadFile"), object: nil, userInfo: imageData)
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            if self.isMovie {
                do {
                    try FileManager.default.moveItem(at: self.attachmentVideoUrl, to: self.fileUrl)
                    print("movie saved")
                } catch {
                    print(error)
                }
            }else{
                self.saveImage(image: self.attachmentImage)
            }
            
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !self.uploadFile && !self.isCopy {
            URL.deleteFile(documentPath: self.fileUrl.path)
        }
    }
    
    func saveImage(image : UIImage){
        var imageHeight = 0.0
        var imageWidth = 0.0
        if(image.size.width > image.size.height && image.size.width > 1920) {
            imageWidth = 1920.0
            imageHeight = Double((1920.0 *  image.size.height) / image.size.width)
        }else if(image.size.height > image.size.width && image.size.height > 1920){
            imageHeight = 1920.0
            imageWidth = Double((1920.0 *  image.size.width) / image.size.height)
        }else{
            imageHeight = Double(image.size.height)
            imageWidth = Double(image.size.width)
        }
        let image = image.sd_resizedImage(with: CGSize.init(width: imageWidth, height: imageHeight) , scaleMode: .fill)!
        /* image = UIImage.init(data: image.jpeg(.lowest)!)!
         print("Image size \(image.getSizeIn(.megabyte)) mb")*/
        
        if let data = image.jpegData(compressionQuality: 1.0) {
            try? data.write(to: self.fileUrl)
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
