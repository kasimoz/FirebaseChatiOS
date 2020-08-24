//
//  PostViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 11.08.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import AVFoundation
import Firebase

class PostViewController: UIViewController {
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    var database = Database.database().reference()
    var receiverData : [String: Any]!
    var roomUID = ""
    var type = ""
    var fileUrl = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        if let roomId = receiverData["roomId"] as? String {
            self.roomUID = roomId
        }
        DispatchQueue.main.async {
            self.toLabel.text = self.receiverData["username"] as? String
            if let item = self.extensionContext?.inputItems[0] as? NSExtensionItem {
                for i in item.attachments! {
                    if i.hasItemConformingToTypeIdentifier("public.plain-text") {
                        self.type = "text"
                        i.loadItem(forTypeIdentifier: "public.plain-text") { item, _ in
                            let text = item as? String
                            DispatchQueue.main.async {
                                self.textLabel.text = text
                            }
                        }
                    }else if i.hasItemConformingToTypeIdentifier("public.url") {
                        self.type = "url"
                        i.loadItem(forTypeIdentifier: "public.url") { item, _ in
                            let text = item as! URL?
                            DispatchQueue.main.async {
                                self.textLabel.text = text?.absoluteString
                            }
                        }
                    }else if i.hasItemConformingToTypeIdentifier("public.jpeg"){
                        self.type = "image"
                        i.loadItem(forTypeIdentifier: "public.jpeg") { item, _ in
                            DispatchQueue.main.async {
                                var imgData : Data!
                                self.fileUrl = ""
                                if let url = item as? URL {
                                    imgData = try! Data.init(contentsOf: url)
                                    self.fileUrl = url.path
                                }
                                self.imageView.image = UIImage.init(data: imgData)
                            }
                        }
                    }else if i.hasItemConformingToTypeIdentifier("public.png")  {
                        self.type = "image"
                        i.loadItem(forTypeIdentifier: "public.png") { item, _ in
                            DispatchQueue.main.async {
                                var imgData : Data!
                                self.fileUrl = ""
                                if let url = item as? URL {
                                    imgData = try! Data.init(contentsOf: url)
                                    self.fileUrl = url.path
                                }
                                
                                self.imageView.image = UIImage.init(data: imgData)
                            }
                        }
                    }else if i.hasItemConformingToTypeIdentifier("public.mpeg-4")  {
                        self.type = "video"
                        i.loadItem(forTypeIdentifier: "public.mpeg-4") { item, _ in
                            DispatchQueue.main.async {
                                self.fileUrl = ""
                                if let url = item as? URL {
                                    self.imageView.image = url.generateThumb(original: true)
                                    self.fileUrl = url.path
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func post(_ sender: Any) {
        switch self.type {
        case "text":
            self.sendMessageToFirebase(message: self.textLabel.text!, lastMessage: self.textLabel.text!, type: "text")
            break
        case "url":
            self.sendMessageToFirebase(message: self.textLabel.text!, lastMessage: self.textLabel.text!, type: "text")
            break
        case "image":
            self.uploadFile(self.fileUrl, isMovie: false)
            break
        case "video":
            self.uploadFile(self.fileUrl, isMovie: true)
            break
        default:
            break
        }
    }
    
    func uploadFile(_ filePath : String , isMovie : Bool) {
        let fileFolder = isMovie ? "videos/" : "images/"
        let type = isMovie ? "video" : "image"
        let attachmentFileName = "\(UUID().uuidString).\(isMovie ? "mp4" : "jpg")"
        let fileRef = Storage.storage().reference().child("\(fileFolder)\(attachmentFileName)")
        let fileThumbRef = Storage.storage().reference().child("\(fileFolder)thumb_\(attachmentFileName)")
        let file = isMovie ? (NSData(contentsOf: URL.init(string: "file://" + filePath)!) as Data?) : UIImage.init(contentsOfFile: filePath)!.jpegData(compressionQuality: 1.0)!
        let thumb =  isMovie ?  URL.init(string: "file://" + filePath)!.generateThumb()!.jpegData(compressionQuality: 1.0)! : UIImage.init(contentsOfFile: filePath)!.thumbImage2().jpegData(compressionQuality: 1.0)!
        let metadataFile = StorageMetadata()
        metadataFile.contentType = isMovie ? "video/mp4" : "image/jpeg"
        let metadataThumb = StorageMetadata()
        metadataThumb.contentType = "image/jpeg"
        let uploadTask = fileRef.putData(file!, metadata: metadataFile)
        self.sliderAlert(message: "Sending \(type)...", completion: { slider in
            if slider == nil {
                uploadTask.cancel()
                self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                return
            }
            let _ = fileThumbRef.putData(thumb, metadata: metadataThumb) { (metadata, error) in
                guard let _ = metadata else {
                    // Uh-oh, an error occurred!
                    return
                }

                // Listen for state changes, errors, and completion of the upload.
                uploadTask.observe(.resume) { snapshot in
                    // Upload resumed, also fires when the upload starts
                }
                
                uploadTask.observe(.pause) { snapshot in
                    // Upload paused
                    self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                }
                
                uploadTask.observe(.progress) { snapshot in
                    // Upload reported progress
                    let percentComplete = 100.0 * Double(snapshot.progress!.completedUnitCount)
                        / Double(snapshot.progress!.totalUnitCount)
                    print(percentComplete)
                    slider?.setValue(Float(percentComplete), animated: true)
                }
                
                uploadTask.observe(.success) { snapshot in
                    self.sendMessageToFirebase(message: "\(attachmentFileName)", lastMessage: "\(fileFolder)\(attachmentFileName)", type: type)
                }
            }
        })
        
    }
    
    func sendMessageToFirebase(message : String, lastMessage : String, type :String, date : Int64 = Date().milliseconds){
        if self.roomUID.isEmpty {
            self.createDatabase()
        }
        let ref = self.database.child("chatMessages")
        let ref2 = self.database.child("chats")
        let message = [
            "sentBy": Auth.auth().currentUser!.uid,
            "message": message,
            "type": type,
            "messageDate": date,
            "timestamp" : ServerValue.timestamp()] as [String : Any]
        let messageUID = ref.childByAutoId().key!
        ref.child(self.roomUID).child(messageUID).setValue(message)
        let lastMessageSend = [
            "sentBy": Auth.auth().currentUser!.uid,
            "message": lastMessage,
            "type": type,
            "date": date,
            "timestamp" : ServerValue.timestamp()] as [String : Any]
        ref2.child(self.roomUID).child("message").setValue(lastMessageSend)
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    
    func createDatabase() {
        let ref = database.child("userChats")
        let ref2 = database.child("chats")
        roomUID = ref.child(Auth.auth().currentUser!.uid).childByAutoId().key!
        ref.child(Auth.auth().currentUser!.uid).child(roomUID).setValue(self.receiverData["id"] as! String)
        ref.child(self.receiverData["id"] as! String).child(roomUID).setValue(Auth.auth().currentUser!.uid)
        ref2.child(roomUID).child("members").child(Auth.auth().currentUser!.uid).setValue("")
        ref2.child(roomUID).child("members").child(self.receiverData["id"] as! String).setValue("")
    }
    
    
    func sliderAlert(message : String, completion: @escaping (_ result: UISlider?)->()){
        
        //get the Slider values from UserDefaults
        let defaultSliderValue = 0.0
        
        //create the Alert message with extra return spaces
        let sliderAlert = UIAlertController(title: message , message: nil, preferredStyle: .alert)
        
        //create a Slider and fit within the extra message spaces
        //add the Slider to a Subview of the sliderAlert
        let slider = UISlider(frame:CGRect.zero)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.setThumbImage(UIImage(), for: .normal)
        slider.minimumValue = 1
        slider.maximumValue = 100
        slider.value = Float(defaultSliderValue)
        slider.isContinuous = true
        slider.tintColor = .systemBlue
        slider.isUserInteractionEnabled = false
        sliderAlert.view.addSubview(slider)
        
        let bottomConstraint = slider.bottomAnchor.constraint(equalTo: sliderAlert.view.bottomAnchor)
        bottomConstraint.isActive = true
        bottomConstraint.constant = -45
        
        slider.leftAnchor.constraint(equalToSystemSpacingAfter: sliderAlert.view.leftAnchor, multiplier: 0.0).isActive = true
        slider.rightAnchor.constraint(equalToSystemSpacingAfter: sliderAlert.view.rightAnchor, multiplier: 0.0).isActive = true
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { result in
            completion(nil)
        })
        
        sliderAlert.addAction(cancelAction)
        
        self.present(sliderAlert, animated: true, completion: {
            completion(slider)
        })
    }
    
}

extension URL
{
    func generateThumb(original : Bool = false) -> UIImage? {
        do {
            let asset = AVURLAsset(url: self)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imageGenerator.copyCGImage(at: .zero,
                                                         actualTime: nil)
            if original {
                return UIImage(cgImage: cgImage)
                
            }else{
                return UIImage(cgImage: cgImage).thumbImage2()
            }
        } catch {
            print(error.localizedDescription)
            
            return nil
        }
    }
}


extension Date {
    
    var milliseconds:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}


extension UIImage {
    
    func thumbImage2(size : CGFloat = 196.0) -> UIImage {
        var imageHeight : CGFloat = 0.0
        var imageWidth : CGFloat = 0.0
        if(self.size.width > self.size.height ) {
            imageHeight = size
            imageWidth = (size *  self.size.width) / self.size.height
        }else {
            imageWidth = size
            imageHeight = (size *  self.size.height) / self.size.width
        }
        return self.sd_resizedImage(with: CGSize.init(width: imageWidth, height: imageHeight) , scaleMode: .fill)!
    }
    
}
