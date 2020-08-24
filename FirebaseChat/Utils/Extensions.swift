//
//  Extensions.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 16.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import ContactsUI
import AVFoundation

extension UIColor {
    convenience init(hexString: String, alpha: CGFloat = 1.0) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)s
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: alpha)
    }
    
    
    public func setOpacity(_ opacity: CGFloat) -> UIColor {
        let rgb = self.cgColor.components
        return UIColor(red: rgb![0], green: rgb![1], blue: rgb![2], alpha: opacity)
    }
}

extension UIView {
    var allSubviews: [UIView] {
        return subviews.flatMap { [$0] + $0.allSubviews }
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
    
    func findSubViews(_ T: AnyClass) -> [UIView] {
        
        var array = [UIView]()
        for vw in self.subviews {
            if vw.isKind(of: T) {
                array.append(vw)
            } else {
                array += vw.findSubViews(T)
            }
        }
        return array
    }
    
    var outermostOrigin: CGPoint {
        return self.superview!.convert(self.frame.origin, to:nil)
    }
}

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    func setRounded() {
        self.layer.cornerRadius = (self.frame.width / 2)
        self.layer.masksToBounds = true
    }
    
    @IBInspectable var roundRight: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            var cornerMask = CACornerMask()
            cornerMask.insert(.layerMinXMinYCorner)
            cornerMask.insert(.layerMaxXMinYCorner)
            cornerMask.insert(.layerMinXMaxYCorner)
            self.layer.cornerRadius = newValue
            self.layer.maskedCorners = cornerMask
        }
    }
    
    @IBInspectable var roundLeft: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            var cornerMask = CACornerMask()
            cornerMask.insert(.layerMinXMinYCorner)
            cornerMask.insert(.layerMaxXMinYCorner)
            cornerMask.insert(.layerMaxXMaxYCorner)
            self.layer.cornerRadius = newValue
            self.layer.maskedCorners = cornerMask
        }
    }
    
    @IBInspectable var left: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            var cornerMask = CACornerMask()
            cornerMask.insert(.layerMinXMinYCorner)
            cornerMask.insert(.layerMinXMaxYCorner)
            self.layer.cornerRadius = newValue
            self.layer.maskedCorners = cornerMask
        }
    }
    
    
}

extension UIViewController : CNContactViewControllerDelegate{
    
    func addPhoneNumber(name : String, phNo : String) {
        let store = CNContactStore()
        let contact = CNMutableContact()
        let array = name.split(separator: " ").map(String.init)
        let homePhone = CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue :phNo ))
        contact.phoneNumbers = [homePhone]
        contact.givenName = array.first ?? ""
        contact.familyName = array.last ?? ""
        let controller = CNContactViewController(forNewContact: contact)
        controller.contactStore = store
        controller.delegate = self
        //self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController!.pushViewController(controller, animated: true)
    }
    
    public func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        self.navigationController?.popViewController(animated: true)
    }
    public func contactViewController(_ viewController: CNContactViewController, shouldPerformDefaultActionFor property: CNContactProperty) -> Bool {
        return true
    }
    
    func viewTouch () -> UITapGestureRecognizer {
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.touchAction))
        self.view.addGestureRecognizer(gesture)
        return gesture
    }
    
    @objc func touchAction(sender : UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    func removeGesture(gesture : UITapGestureRecognizer ){
        self.view.removeGestureRecognizer(gesture)
    }
    
    
    func alertAttachment(completion: @escaping (_ result: Constants.AttachmentType)->()) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let photoAction = UIAlertAction(title: "Photo", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            completion(.Photo)
        })
        photoAction.setValue(UIImage.init(systemName: "camera.fill"), forKey: "image")
        photoAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        photoAction.setValue(Constants.blue, forKey: "titleTextColor")
        alert.addAction(photoAction)
        let videoAction = UIAlertAction(title: "Video", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            completion(.Video)
        })
        videoAction.setValue(UIImage.init(systemName: "video.fill"), forKey: "image")
        videoAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        videoAction.setValue(Constants.blue, forKey: "titleTextColor")
        alert.addAction(videoAction)
        let galleryAction = UIAlertAction(title: "Gallery", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            completion(.Gallery)
        })
        galleryAction.setValue(UIImage.init(systemName: "photo.fill"), forKey: "image")
        galleryAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        galleryAction.setValue(Constants.blue, forKey: "titleTextColor")
        alert.addAction(galleryAction)
        let locationAction = UIAlertAction(title: "Location", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            completion(.Location)
        })
        locationAction.setValue(UIImage.init(systemName: "mappin.and.ellipse"), forKey: "image")
        locationAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        locationAction.setValue(Constants.blue, forKey: "titleTextColor")
        alert.addAction(locationAction)
        let contactAction = UIAlertAction(title: "Contact", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            completion(.Contact)
        })
        contactAction.setValue(UIImage.init(systemName: "person.crop.circle.fill"), forKey: "image")
        contactAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        contactAction.setValue(Constants.blue, forKey: "titleTextColor")
        alert.addAction(contactAction)
        let cancelAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: {(action:UIAlertAction!) in
            completion(.Cancel)
        })
        cancelAction.setValue(Constants.orange, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX , y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = .init(rawValue: 0)
        }
        //  alert.view.tintColor = Constants.blue
        self.present(alert, animated: true, completion: nil)
        
        return alert
    }
    
    
    func alertProfileImage(completion: @escaping (_ result: Constants.PhotoEditType)->()){
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let takeAction = UIAlertAction(title: "Take Photo", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            completion(.Take)
        })
        takeAction.setValue(UIImage.init(systemName: "camera.fill"), forKey: "image")
        takeAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        takeAction.setValue(Constants.blue, forKey: "titleTextColor")
        alert.addAction(takeAction)
        let chooseAction = UIAlertAction(title: "Choose Photo", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            completion(.Choose)
        })
        chooseAction.setValue(UIImage.init(systemName: "photo.fill"), forKey: "image")
        chooseAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        chooseAction.setValue(Constants.blue, forKey: "titleTextColor")
        alert.addAction(chooseAction)
        let deleteAction = UIAlertAction(title: "Delete Photo", style: UIAlertAction.Style.default, handler: {(action:UIAlertAction!) in
            completion(.Delete)
        })
        deleteAction.setValue(UIImage.init(systemName: "trash.fill"), forKey: "image")
        deleteAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        deleteAction.setValue(UIColor.red, forKey: "titleTextColor")
        alert.addAction(deleteAction)
        
        let cancelAction = UIAlertAction(title: "Close", style: UIAlertAction.Style.cancel, handler: {(action:UIAlertAction!) in
            completion(.Cancel)
        })
        cancelAction.setValue(Constants.orange, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX , y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = .init(rawValue: 0)
        }
        //  alert.view.tintColor = Constants.blue
        self.present(alert, animated: true, completion: nil)
    }
    
    func signOutAlert(completion: @escaping (_ result: Bool)->()){
        let alert = UIAlertController(title: nil, message: "Do you want to sign out?", preferredStyle: UIAlertController.Style.actionSheet)
        let yesAction = UIAlertAction(title: "Yes", style: UIAlertAction.Style.destructive, handler: {(action:UIAlertAction!) in
            completion(true)
        })
        alert.addAction(yesAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: {(action:UIAlertAction!) in
            completion(false)
        })
        alert.addAction(cancelAction)
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX , y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = .init(rawValue: 0)
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func setNetwokView() -> UIView {
        
        let indicator = UIActivityIndicatorView.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        indicator.hidesWhenStopped = true
        indicator.tintColor = .black
        indicator.startAnimating()
        
        let titleLabel = UILabel(frame: CGRect(x: 14, y: -7, width: 0, height: 0))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = .black
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
        titleLabel.text = "Waiting for network"
        titleLabel.textAlignment = .left
        titleLabel.sizeToFit()
        
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: 146, height: 0))
        titleView.addSubview(indicator)
        titleView.addSubview(titleLabel)
        
        return titleView
    }
    
    func saveImageOrVideo(isMovie : Bool, attachmentFileName : String, image : UIImage? = nil, attachmentVideoUrl : URL? = nil, completion: @escaping (_ result: URL?)->()){
        let documentsURL = URL.createFolder(folderName: isMovie ? "Videos" : "Photos")
        let fileUrl = documentsURL?.appendingPathComponent(attachmentFileName)
        if isMovie {
            /*do {
             try FileManager.default.copyItem(at: attachmentVideoUrl!, to: fileUrl!)
             completion(fileUrl!)
             } catch {
             completion(nil)
             }*/
            let avAsset = AVURLAsset(url: attachmentVideoUrl!, options: nil)
            
            let startDate = Foundation.Date()
            
            //Create Export session
            let exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough)
            
            let documentsURL = URL.createFolder(folderName: "Videos")
            let filePath = documentsURL?.appendingPathComponent(attachmentFileName)
            
            URL.deleteFile(documentPath: filePath!.path)
            
            exportSession!.outputURL = filePath
            exportSession!.outputFileType = AVFileType.mp4
            exportSession!.shouldOptimizeForNetworkUse = true
            let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
            let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
            exportSession?.timeRange = range
            
            exportSession!.exportAsynchronously(completionHandler: {() -> Void in
                switch exportSession!.status {
                case .failed:
                    print("%@",exportSession?.error as Any)
                    completion(nil)
                case .cancelled:
                    print("Export canceled")
                    completion(nil)
                case .completed:
                    //Video conversion finished
                    let endDate = Foundation.Date()
                    
                    let time = endDate.timeIntervalSince(startDate)
                    print(time)
                    print("Successful!")
                    print(exportSession?.outputURL as Any)
                    let mediaPath = exportSession?.outputURL
                    completion(mediaPath)
                default:
                    completion(nil)
                    break
                }
                
            })
        }else{
            var imageHeight = 0.0
            var imageWidth = 0.0
            if(image!.size.width > image!.size.height && image!.size.width > 1920) {
                imageWidth = 1920.0
                imageHeight = Double((1920.0 *  image!.size.height) / image!.size.width)
            }else if(image!.size.height > image!.size.width && image!.size.height > 1920){
                imageHeight = 1920.0
                imageWidth = Double((1920.0 *  image!.size.width) / image!.size.height)
            }else{
                imageHeight = Double(image!.size.height)
                imageWidth = Double(image!.size.width)
            }
            let image = image!.sd_resizedImage(with: CGSize.init(width: imageWidth, height: imageHeight) , scaleMode: .fill)!
            /* image = UIImage.init(data: image.jpeg(.lowest)!)!
             print("Image size \(image.getSizeIn(.megabyte)) mb")*/
            
            if let data = image.jpegData(compressionQuality: 1.0) {
                do {
                    try data.write(to: fileUrl!)
                    completion(fileUrl!)
                } catch {
                    completion(nil)
                }
                
            }
        }
    }
}


extension Dictionary {
    func toJsonString() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
            
            let jsonString = String(data: jsonData, encoding: .utf8)
            
            return jsonString ?? ""
        } catch {
            print(error.localizedDescription)
            return ""
        }
    }
    
}

extension Int64 {
    func dateToDate() -> String {
        let time1 = 24 * 60 * 60 * 1000
        let time2 = 7 * 24 * 60 * 60 * 1000
        let formatter = DateFormatter()
        var format = "dd.MM.yy HH:mm:ss.SSS"
        if Date().toString() == Date.init(milliseconds: self).toString() {
            format = "HH:mm"
        }else if (Date().millisecondsSince1970 - Date.init(milliseconds: self).millisecondsSince1970) < Int64(time1) {
            format = "'yday' HH:mm"
        }else if (Date().millisecondsSince1970 - Date.init(milliseconds: self).millisecondsSince1970) < Int64(time2) {
            format = "EEE HH:mm"
        }else {
            format = "dd.MM.yy HH:mm"
        }
        formatter.dateFormat = format
        
        return formatter.string(from: Date.init(milliseconds: self))
    }
}

extension Date {
    
    func toString(format : String = "dd MM yyyy") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
    
    
    func addingDay(_ value : Int)-> Date {
        return self.addingTimeInterval(TimeInterval(value * 24 * 60 * 60))
    }
    
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

extension UITextView {
    var numberOfLines: Int {
        let numberOfGlyphs = self.layoutManager.numberOfGlyphs
        var index = 0, numberOfLines = 0
        var lineRange = NSRange(location: NSNotFound, length: 0)
        
        while index < numberOfGlyphs {
            self.layoutManager.lineFragmentRect(forGlyphAt: index, effectiveRange: &lineRange)
            index = NSMaxRange(lineRange)
            numberOfLines += 1
        }
        
        return numberOfLines
    }
}


extension LastMessage {
    
    var getMessage : String {
        switch self.type {
        case "text" :
            return self.message
        case "image" :
            return "📷 Photo"
        case "video" :
            return "🎥 Video"
        case "contact" :
            return self.message
        case "record" :
            return self.message
        case "location" :
            return self.message
        case "reply" :
            return self.message
        default:
            return ""
        }
    }
}

extension Message {
    
    var getType : Constants.CellType {
        let isMe = self.sentBy == Auth.auth().currentUser?.uid
        switch self.type {
        case "text" :
            return  isMe ? Constants.CellType.TextSender : Constants.CellType.TextReceiver
        case "image" :
            return isMe ? Constants.CellType.ImageSender : Constants.CellType.ImageReceiver
        case "video" :
            return isMe ? Constants.CellType.VideoSender : Constants.CellType.VideoReceiver
        case "contact" :
            return isMe ? Constants.CellType.ContactSender : Constants.CellType.ContactReceiver
        case "record" :
            return isMe ? Constants.CellType.RecordSender : Constants.CellType.RecordReceiver
        case "location" :
            return isMe ? Constants.CellType.LocationSender : Constants.CellType.LocationReceiver
        case "reply" :
            return isMe ? Constants.CellType.ReplySender : Constants.CellType.ReplyReceiver
        default:
            return Constants.CellType.Unread
        }
    }
    
    var getMessage : String {
        let first = message.split(separator: "|").first?.trimmingCharacters(in: .whitespaces) ?? ""
        let last = message.split(separator: "|").last?.trimmingCharacters(in: .whitespaces) ?? ""
        switch self.type {
        case "text" :
            return  message
        case "image" :
            return "📷 Photo"
        case "video" :
            return "🎥 Video"
        case "contact" :
            return "👤 \(first)"
        case "record" :
            return "🎙️ \(String(describing: Int(first)?.getTime() ?? "00:00"))"
        case "location" :
            return "📍 Location"
        case "reply" :
            return last
        default:
            return ""
        }
    }
    
    var copyVisible : Bool {
        switch self.type {
        case "text" :
            return true
        case "image" :
            return true
        case "video" :
            return false
        case "contact" :
            return false
        case "record" :
            return false //
        case "location" :
            return true
        case "reply" :
            return false
        default:
            return false
        }
    }
    
}


extension UITableView {
    
    func scrollToBottom(count : Int = 0, animated : Bool = true){
        
        DispatchQueue.main.async {
            let indexPath = IndexPath(
                row: self.numberOfRows(inSection:  self.numberOfSections-1) - 1 + count  ,
                section: self.numberOfSections - 1)
            if indexPath.row > 0 {
                self.scrollToRow(at: indexPath, at: .bottom, animated: animated)
            }
        }
    }
    
    
    func scrollToTop() {
        
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: 0, section: 0)
            self.scrollToRow(at: indexPath, at: .top, animated: false)
        }
    }
}

extension Array {
    func indexPaths(numberOfSection : Int = 1) -> [IndexPath]{
        let initialIndexPath = IndexPath.init(row: 0, section: 0)
        let indexPaths: [IndexPath] = (0..<numberOfSection).flatMap { (section) -> ([IndexPath]) in
            // find initial item in section
            let initialItemIndex = section == initialIndexPath.section ? initialIndexPath.item  : 0
            
            // iterate all items in section
            return (initialItemIndex..<(self.count)).compactMap { item in
                return IndexPath(item: item, section: section)
            }
        }
        return indexPaths
    }
}
extension Int {
    func getTime() -> String {
        let sec = (self) % 60
        let min = ((self) / (60)) % 60
        return String.init(format: "%02d:%02d", min, sec)
    }
}

extension UISlider {
    func smallerThumb(user : Bool){
        
        let thumbView = UIView.init(frame:  CGRect(x: 0, y: 6, width: 12, height: 12))
        thumbView.layer.cornerRadius = 6
        thumbView.backgroundColor =  user ? Constants.orange : Constants.blue
        
        
        let renderer = UIGraphicsImageRenderer(bounds: thumbView.bounds)
        let image = renderer.image { rendererContext in
            thumbView.layer.render(in: rendererContext.cgContext)
        }
        self.setThumbImage(image, for: .normal)
    }
}

struct JSON {
    static let encoder = JSONEncoder()
}
extension Encodable {
    subscript(key: String) -> Any? {
        return dictionary[key]
    }
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSON.encoder.encode(self))) as? [String: Any] ?? [:]
    }
}

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}

extension UIImage {
    
    public enum DataUnits: String {
        case byte, kilobyte, megabyte, gigabyte
    }
    
    func getSizeIn(_ type: DataUnits)-> String {
        
        guard let data = self.pngData() else {
            return ""
        }
        
        var size: Double = 0.0
        
        switch type {
        case .byte:
            size = Double(data.count)
        case .kilobyte:
            size = Double(data.count) / 1024
        case .megabyte:
            size = Double(data.count) / 1024 / 1024
        case .gigabyte:
            size = Double(data.count) / 1024 / 1024 / 1024
        }
        
        return String(format: "%.2f", size)
    }
    
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    func jpeg(_ jpegQuality: JPEGQuality) -> Data? {
        return jpegData(compressionQuality: jpegQuality.rawValue)
    }
    
    func thumbImage(size : CGFloat = 196.0) -> UIImage {
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
    
    func square() -> UIImage? {
        
        if size.width == size.height {
            
            return self
            
        }
        
        
        let cropWidth = min(size.width, size.height)
        
        let cropRect = CGRect(
            
            x: (size.width - cropWidth) * scale / 2.0,
            
            y: (size.height - cropWidth) * scale / 2.0,
            
            width: cropWidth * scale,
            
            height: cropWidth * scale
        )
        
        guard let imageRef = cgImage?.cropping(to: cropRect) else {
            
            return nil
            
        }
        
        return UIImage(cgImage: imageRef, scale: scale, orientation: imageOrientation)
        
    }
}

extension URL {
    static func createFolder(folderName: String) -> URL? {
        let fileManager = FileManager.default
        // Get document directory for device, this should succeed
        if let documentDirectory = fileManager.urls(for: .documentDirectory,
                                                    in: .userDomainMask).first {
            // Construct a URL with desired folder name
            let folderURL = documentDirectory.appendingPathComponent(folderName)
            // If folder URL does not exist, create it
            if !fileManager.fileExists(atPath: folderURL.path) {
                do {
                    // Attempt to create folder
                    try fileManager.createDirectory(atPath: folderURL.path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
                } catch {
                    // Creation failed. Print error & return nil
                    print(error.localizedDescription)
                    return nil
                }
            }
            // Folder either exists, or was created. Return URL
            return folderURL
        }
        // Will only be called if document directory not found
        return nil
    }
    
    static func fileExists(folderName: String,fileName: String) -> Bool? {
        let fileManager = FileManager.default
        // Get document directory for device, this should succeed
        if let documentDirectory = fileManager.urls(for: .documentDirectory,
                                                    in: .userDomainMask).first {
            // Construct a URL with desired folder name
            let fileURL = documentDirectory.appendingPathComponent("\(folderName)/"+fileName)
            // If folder URL does not exist, create it
            if !fileManager.fileExists(atPath: fileURL.path) {
                return false
            }
            // Folder either exists, or was created. Return URL
            return true
        }
        // Will only be called if document directory not found
        return false
    }
    
    func listFilesFromDownloadsFolder() -> [String]?
    {
        let fileManager = FileManager.default
        do {
            return try fileManager.contentsOfDirectory(atPath: self.path)
        } catch let error as NSError {
            print("Error: \(error.domain)")
            return []
        }
    }
    
    static func deleteFolder(folderName: String) {
        let fileManager = FileManager.default
        // Get document directory for device, this should succeed
        if let documentDirectory = fileManager.urls(for: .documentDirectory,
                                                    in: .userDomainMask).first {
            // Construct a URL with desired folder name
            let folderURL = documentDirectory.appendingPathComponent(folderName)
            // If folder URL does not exist, create it
            if fileManager.fileExists(atPath: folderURL.path) {
                try? fileManager.removeItem(at: folderURL)
            }
        }
    }
    
    static func deleteFile(documentPath: String) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(atPath: documentPath)
        } catch let error as NSError {
            print("Error: \(error.domain)")
        }
    }
    
    static func renameFile(documentPath: URL, exten : String) {
        let fileManager = FileManager.default
        // Get document directory for device, this should succeed
        do {
            let newURL = documentPath.deletingPathExtension().appendingPathExtension(exten)
            try fileManager.moveItem(at: documentPath, to: newURL)
        } catch let error as NSError {
            print("Error: \(error.domain)")
        }
    }
    
    func generateThumbnail(original : Bool = false) -> UIImage? {
        do {
            let asset = AVURLAsset(url: self)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imageGenerator.copyCGImage(at: .zero,
                                                         actualTime: nil)
            if original {
                return UIImage(cgImage: cgImage)
                
            }else{
                return UIImage(cgImage: cgImage).thumbImage()
            }
        } catch {
            print(error.localizedDescription)
            
            return nil
        }
    }
    
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        let end = index(start, offsetBy: min(self.count - range.lowerBound,
                                             range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }
    
    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: max(0, range.lowerBound))
        return String(self[start...])
    }
    
    func convertBase64ToImage() -> UIImage {
        let imageData = Data(base64Encoded: self, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)!
        return UIImage(data: imageData)!
    }
    
    func toDouble() -> Double? {
        return Double(self)
    }
}

extension StorageReference {
    
    func loadAudio(indicator: UIActivityIndicatorView,fileName :String, completion: @escaping (_ result: String)->()){
        if URL.fileExists(folderName: "Records", fileName: fileName) ?? false {
            completion(fileName)
        }else{
            indicator.startAnimating()
            let documentsURL = URL.createFolder(folderName: "Records")
            let localURL = documentsURL!.appendingPathComponent(fileName)
            
            self.child(fileName).write(toFile: localURL) { url, error in
                if error != nil {
                    indicator.stopAnimating()
                } else {
                    indicator.stopAnimating()
                    completion(fileName)
                }
            }
        }
    }
    
    func loadPhoto(indicator: UIActivityIndicatorView,fileName :String, completion: @escaping (_ result: String)->()){
        if URL.fileExists(folderName: "Photos", fileName: fileName) ?? false {
            completion(fileName)
        }else{
            indicator.startAnimating()
            let documentsURL = URL.createFolder(folderName: "Photos")
            let localURL = documentsURL!.appendingPathComponent(fileName)
            
            self.child(fileName).write(toFile: localURL) { url, error in
                if error != nil {
                    indicator.stopAnimating()
                } else {
                    indicator.stopAnimating()
                    completion(fileName)
                }
            }
        }
    }
    
    func loadVideo(indicator: UIActivityIndicatorView,fileName :String, completion: @escaping (_ result: String)->()){
        if URL.fileExists(folderName: "Videos", fileName: fileName) ?? false {
            completion(fileName)
        }else{
            indicator.startAnimating()
            let documentsURL = URL.createFolder(folderName: "Videos")
            let localURL = documentsURL!.appendingPathComponent(fileName)
            
            self.child(fileName).write(toFile: localURL) { url, error in
                if error != nil {
                    indicator.stopAnimating()
                } else {
                    indicator.stopAnimating()
                    completion(fileName)
                }
            }
        }
    }
    
    
    
}


extension UserDefaults {
    
    public func optionalBool(forKey defaultName: String) -> Bool? {
        let defaults = self
        if let value = defaults.value(forKey: defaultName) {
            return value as? Bool
        }
        return nil
    }
    
    func setUser(username : String, phoneNumber : String, status : String, image : String){
        let defaults = self
        defaults.setValue(username, forKey: "username")
        defaults.setValue(phoneNumber, forKey: "phoneNumber")
        defaults.setValue(status, forKey: "status")
        defaults.setValue(image, forKey: "image")
    }
    
    func setUser(username : String, status : String){
        let defaults = self
        defaults.setValue(username, forKey: "username")
        defaults.setValue(status, forKey: "status")
    }
    
    func setUser(image : String){
        let defaults = self
        defaults.setValue(image, forKey: "image")
    }
    
    func getUser() -> User {
        let defaults = self
        return User.init(username: defaults.string(forKey: "username") ?? "", phoneNumber: defaults.string(forKey: "phoneNumber") ?? "", status: defaults.string(forKey: "status") ?? Constants.status, image: defaults.string(forKey: "image") ?? Constants.pImage)
    }
}


extension UIView {
    /// Remove all subview
    func removeAllSubviews() {
        subviews.forEach { $0.removeFromSuperview() }
    }
    
    /// Remove all subview with specific type
    func removeAllSubviews<T: UIView>(type: T.Type) {
        subviews
            .filter { $0.isMember(of: type) }
            .forEach { $0.removeFromSuperview() }
    }
}



