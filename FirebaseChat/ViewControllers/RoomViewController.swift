//
//  RoomViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 17.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import ObjectMapper
import AVFoundation
import ContactsUI
import MobileCoreServices

class RoomViewController: UIViewController, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, UIGestureRecognizerDelegate{
    
    @IBOutlet weak var elapsedTime: UILabel!
    @IBOutlet weak var replyLine: UIView!
    @IBOutlet weak var replyMarker: UIImageView!
    @IBOutlet weak var replyThumb: UIImageView!
    @IBOutlet weak var replyMessage: UILabel!
    @IBOutlet weak var replySender: UILabel!
    @IBOutlet weak var replyView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var slideToDelete: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var messageViewBottom: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottom: NSLayoutConstraint!
    @IBOutlet weak var centerView: UIView!
    var receiverData : [String: Any]!
    var userSubtitle: String = ""
    var roomUID = ""
    var isOnline = false
    var isExistChat = false
    var isTyping = false
    var isPause = false
    var time = Date().millisecondsSince1970
    var timer : Timer!
    var recordTimer : Timer!
    var playTimer : Timer!
    var playedRecordIndex = -1
    var unreadCount = 0
    var currentTime : Float = 0.0
    var replyPosition = -1
    var attachmentFileName = ""
    var attachmentImage : UIImage!
    var attachmentVideoUrl : URL!
    var coordinate = ""
    var sentBy = ""
    var isMovie = false
    var isCopy = false
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var playedSlider : UISlider!
    var profileCGRect : CGRect!
    @IBOutlet weak var messageTextHeight: NSLayoutConstraint!
    @IBOutlet weak var messageText: UITextView!
    @IBOutlet weak var toBottomButton: UIButton!
    var forwardMessage : Message!
    var messageList = [Message]()
    var refMessageList : DatabaseQuery!
    var refMessageList2 : DatabaseQuery!
    var database = Database.database().reference()
    var gesture : UITapGestureRecognizer!
    var selectedIndexPath: IndexPath!
    var profileImageView : UIImageView!
    var segueType  : Constants.SegueType = .none
    var imagePickerController : UIImagePickerController!
    var alertController : UIAlertController!
    var myClosure: (() -> ())?
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.tableView.contentSize.height - self.tableView.contentOffset.y > 1000 {
            self.toBottomButton.isHidden = false
        }else{
            self.toBottomButton.isHidden = true
        }
        
        if scrollView.contentOffset.y == 0 {
            if self.messageList.count == 0 {
                return
            }
            var list = self.convertToMessageArray(items: self.retrieveMessages(roomId: self.roomUID, timestamp: self.messageList.first!.timestamp) ?? [])
            if list.count == 0 {
                return
            }
            list.sort(by: { (first: Message, second: Message) -> Bool in
                Date.init(milliseconds: Int64(first.timestamp)) > Date.init(milliseconds: Int64(second.timestamp))
            })
            let indexPaths = list.indexPaths()
            
            for item in list {
                self.messageList.insert(item, at: 0)
            }
            UIView.performWithoutAnimation {
                self.tableView.insertRows(at: indexPaths, with: .none)
            }
            self.tableView.scrollToRow(at: indexPaths.last!, at: .top, animated: false)
        }
    }
    
    @IBAction func replyClose(_ sender: Any) {
        self.tableViewBottom.constant = 0
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: { result in
            self.replyView.isHidden = true
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.titleView = setTitleView()
        self.messageText.textContainerInset = UIEdgeInsets.init(top: 7, left: 8, bottom: 7, right: 8)
        // Do any additional setup after loading the view.
        if let roomId = receiverData["roomId"] as? String {
            self.roomUID = roomId
            self.messageList = self.convertToMessageArray(items: self.retrieveMessages(roomId: self.roomUID, timestamp: Date().millisecondsSince1970) ?? [])
            self.messageList.sort(by: { (first: Message, second: Message) -> Bool in
                Date.init(milliseconds: Int64(first.timestamp )) < Date.init(milliseconds: Int64(second.timestamp))
            })
            self.tableView.performBatchUpdates({
                self.tableView.reloadData()
            }, completion: { result in
                self.tableView.scrollToBottom(count: 0, animated: false)
                self.tableView.reloadRows(at: self.tableView.visibleCells.indexPaths(), with: .none)
            })
            let ref = Database.database().reference().child("chats").child(roomId).child("members").child(Auth.auth().currentUser!.uid).child("lastSeenMessage")
            ref.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                let lastSeenMessage = snapshot.value as? Int64
                self.getMessageList(roomId: roomId, lastSeenMessage: lastSeenMessage)
            })
            
        }else{
            let ref = Database.database().reference().child("userChats").child(Auth.auth().currentUser!.uid)
            ref.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                for child in snapshot.children.allObjects as! [DataSnapshot] {
                    if child.value as? String == "\(self.receiverData["id"] as! String)" {
                        self.getMessageList(roomId: child.key)
                        break
                    }
                }
                
            })
        }
        
        let ref2 = Database.database().reference().child("users").child("\(receiverData["id"] as! String)")
        ref2.observe(DataEventType.value, with: { (snapshot) in
            let dict = snapshot.value as? [String : AnyObject] ?? [:]
            if dict["online"] as? Bool ?? false{
                self.receiverData["online"] = true
                self.navigationItem.titleView = self.setTitleView()
            }else{
                self.receiverData["online"] = false
                self.receiverData["lastOnlineTime"] = dict["lastOnlineTime"] as? Int64
                self.navigationItem.titleView = self.setTitleView()
            }
        })
        
        
        
        
        self.recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try self.recordingSession.setCategory(.playAndRecord, mode: .default)
            try self.recordingSession.setActive(true)
            self.recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.micButton.isEnabled = true
                    } else {
                        self.micButton.isEnabled = false
                    }
                }
            }
        } catch {
            // failed to record!
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.uploadFile(_:)), name: NSNotification.Name("uploadFile"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.shareLocation(_:)), name: NSNotification.Name("shareLocation"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.shareContact(_:)), name: NSNotification.Name("shareContact"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationMessage(_:)), name: NSNotification.Name("notification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachable(_:)), name: NSNotification.Name("reachable"), object: nil)
        
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        
        if parent == nil
        {
            print("deinit")
            NotificationCenter.default.removeObserver(self)
            refMessageList?.removeAllObservers()
        }
    }
    
    @objc func reachable(_ notification: NSNotification) {
        let result = (notification.userInfo?["reachable"] as? Bool) ?? false
        if result {
            self.navigationItem.titleView = self.setTitleView()
        }else{
            self.navigationItem.titleView = self.setNetwokView()
        }
    }
    
    @objc func notificationMessage(_ notification: NSNotification) {
        if let _ = notification.userInfo?["sender"] as? String {
            if let _ = notification.userInfo?["chatUID"] as? String {
                self.alertController?.dismiss(animated: true, completion: nil)
                imagePickerController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func startTimer(){
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.timerUpdate), userInfo: nil, repeats: true)
    }
    
    @objc func timerUpdate() {
        if !self.roomUID.isEmpty {
            let ref = self.database.child("chats").child(self.roomUID).child("members").child(Auth.auth().currentUser!.uid).child("typing")
            ref.setValue(false)
            self.isTyping = false
        }
    }
    
    
    func setTitleView(typing : Bool = false) -> UIView {
        self.profileImageView = UIImageView(frame: CGRect(x: 0, y: -2, width: 36, height: 36))
        let ref = Storage.storage().reference().child("images/\(receiverData["image"] as? String ?? "")")
        self.profileImageView.sd_setImage(with: ref, placeholderImage: UIImage.init(systemName: "person.crop.circle.fill"))
        self.profileImageView.setRounded()
        self.profileImageView.tintColor = UIColor.init(hexString: "9E9E9E")
        self.profileImageView.contentMode = .scaleAspectFit
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped(_ :)))
        self.profileImageView.isUserInteractionEnabled = true
        self.profileImageView.addGestureRecognizer(tapGestureRecognizer)
        
        let titleLabel = UILabel(frame: CGRect(x: 44, y: -2, width: 0, height: 0))
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = .black
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
        titleLabel.text = receiverData["username"] as? String
        titleLabel.textAlignment = .left
        titleLabel.sizeToFit()
        
        var subtitle = ""
        if typing {
            subtitle = "typing..."
        }else{
            if receiverData["online"] as? Bool ?? false{
                subtitle = "online"
                self.userSubtitle = "online"
                self.isOnline = true
            }else{
                subtitle = "last seen : " + (receiverData["lastOnlineTime"] as! Int64).dateToDate()
                self.userSubtitle = (receiverData["lastOnlineTime"] as! Int64).dateToDate()
                self.isOnline = false
            }
        }
        let subtitleLabel = UILabel(frame: CGRect(x: 44, y: 18, width: 0, height: 0))
        subtitleLabel.backgroundColor = UIColor.clear
        subtitleLabel.textColor = .black
        subtitleLabel.font = UIFont.systemFont(ofSize: 12.0)
        subtitleLabel.text = subtitle
        subtitleLabel.textAlignment = .left
        subtitleLabel.sizeToFit()
        
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 30))
        titleView.addSubview(self.profileImageView)
        titleView.addSubview(titleLabel)
        titleView.addSubview(subtitleLabel)
        
        return titleView
    }
    
    @objc func profileImageTapped(_ tapGestureRecognizer: UITapGestureRecognizer)
    {
        self.profileCGRect = self.profileImageView.superview?.convert(self.profileImageView.frame, to: nil)
        self.profileImageView.frame = self.profileCGRect
        UIApplication.shared.windows.last?.addSubview(self.profileImageView)
        UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {() -> Void in
            self.profileImageView.frame = self.centerView.frame
        }, completion: {(_ finished: Bool) -> Void in
            self.segueType = .profile
            self.performSegue(withIdentifier: "image", sender: nil)
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let indexPath = selectedIndexPath {
            if self.segueType == .imageVideo {
                let folder = self.messageList[indexPath.row].type == "image" ? "images" : "videos"
                let cell = self.tableView.cellForRow(at: indexPath)
                let image = cell?.viewWithTag(1) as! UIImageView
                let ref = Storage.storage().reference().child("\(folder)/thumb_\(self.messageList[indexPath.row].message)")
                image.sd_setImage(with: ref, maxImageSize: 1024 * 1024, placeholderImage: nil, options: .refreshCached, context: nil, progress: nil, completion: { (image_, error, type, url) in
                    image.image = image_?.square()
                })
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.segueType == .profile {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {() -> Void in
                self.profileImageView.frame = self.profileCGRect
            }, completion: {(_ finished: Bool) -> Void in
                self.navigationItem.titleView = self.setTitleView()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                    UIApplication.shared.windows.last?.removeAllSubviews(type: UIImageView.self)
                })
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.playTimer?.invalidate()
        self.audioPlayer?.stop()
        let receiverData : [String: Any] = ["roomId": self.roomUID]
        NotificationCenter.default.post(name: Notification.Name("removeCounter"), object: nil, userInfo: receiverData)
    }
    
    @IBAction func addAttachment(_ sender: Any) {
        self.alertController = self.alertAttachment(completion: { result in
            switch result {
            case .Photo:
                self.imagePicker(type: .camera, captureMode: .photo)
                break
            case .Video:
                self.imagePicker(type: .camera, captureMode: .video)
                break
            case .Gallery:
                self.imagePicker(type: .photoLibrary, captureMode: .none)
                break
            case .Location:
                self.segueType = .none
                self.performSegue(withIdentifier: "shareLocation", sender: nil)
                break
            case .Contact:
                self.segueType = .none
                self.performSegue(withIdentifier: "shareContact", sender: nil)
                break
            case .Cancel:
                break
            }
        })
    }
    
    func imagePicker(type : UIImagePickerController.SourceType, captureMode : Constants.CaptureMode){
        imagePickerController = UIImagePickerController()
        imagePickerController.modalPresentationStyle = .fullScreen
        imagePickerController.sourceType = type
        imagePickerController.allowsEditing = true
        imagePickerController.videoMaximumDuration = TimeInterval(60.0)
        imagePickerController.videoQuality = .typeMedium
        if captureMode == .photo {
            imagePickerController.mediaTypes = [kUTTypeImage as String]
        }else if captureMode == .video {
            imagePickerController.mediaTypes = [kUTTypeMovie as String]
        }else{
            imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        }
        imagePickerController.delegate = self
        self.present(imagePickerController, animated: true)
    }
    
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
                 viewController.navigationItem.title = "your text..!!"

    }
    
    @objc fileprivate func customBtnTapped(_ sender: UIButton) {
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        self.isMovie = info[.mediaType] as? String == "public.movie"
        self.isCopy = false
        if isMovie {
            guard let videoUrl = info[.mediaURL] as? URL else {
                print("No video found")
                picker.dismiss(animated: true)
                return
            }
            picker.dismiss(animated: true, completion: {
                self.segueType = .none
                self.attachmentVideoUrl = videoUrl
                self.attachmentFileName = "\(UUID().uuidString).mp4"
                
                self.saveImageOrVideo(isMovie: true, attachmentFileName: self.attachmentFileName, attachmentVideoUrl: self.attachmentVideoUrl, completion: {
                    fileUrl in
                    if let url = fileUrl {
                        DispatchQueue.main.async {
                             self.uploadFileFromGallery(url.path)
                        }
                    }
                })
            })
        }else {
            guard let image = info[.editedImage] as? UIImage else {
                print("No image found")
                picker.dismiss(animated: true)
                return
            }
            picker.dismiss(animated: true, completion: {
                self.segueType = .none
                self.attachmentImage = image
                self.attachmentFileName = "\(UUID().uuidString).jpg"
                self.saveImageOrVideo(isMovie: false, attachmentFileName: self.attachmentFileName, image: self.attachmentImage, completion: {
                    fileUrl in
                    if let url = fileUrl {
                        self.uploadFileFromGallery(url.path)
                    }
                })
            })
        }
    }
    
    func getMessageList(roomId : String, lastSeenMessage : Int64? = nil){
        self.roomUID = roomId
        self.isExistChat = true
        if(self.messageList.count > 0 ){
            if (lastSeenMessage == nil){
                refMessageList = database.child("chatMessages").child(roomUID).queryOrdered(byChild: "timestamp").queryStarting(atValue: (messageList.last!.timestamp + 1000), childKey: "timestamp")
            }
            else{
                refMessageList = database.child("chatMessages").child(roomUID).queryOrdered(byChild: "timestamp").queryStarting(atValue: (lastSeenMessage! + 1000), childKey: "timestamp")
            }
        }else{
            if (lastSeenMessage == nil){
                refMessageList = database.child("chatMessages").child(roomUID).queryOrdered(byChild: "timestamp").queryStarting(atValue: Date().millisecondsSince1970, childKey: "timestamp")
                let ref =  Database.database().reference().child("chats").child(self.roomUID).child("members").child(Auth.auth().currentUser!.uid).child("lastSeenMessage")
                self.setLastSeenMessage(postRef: ref)
            }
            else{
                refMessageList = database.child("chatMessages").child(roomUID).queryOrdered(byChild: "timestamp").queryStarting(atValue: (lastSeenMessage! + 1000), childKey: "timestamp")
            }
        }
        
        // Get last message from the database
        /*if (lastSeenMessage != nil){
         refMessageList2 = database.child("chatMessages").child(roomUID).queryOrdered(byChild: "timestamp").queryLimited(toLast: 1)
         
         refMessageList2.observe(.childAdded, with: { (snapshot) in
         self.childAdded(snapshot: snapshot)
         })
         }*/
        refMessageList.observe(.childAdded, with: { (snapshot) in
            self.childAdded(snapshot: snapshot)
        })
        
        let ref = database.child("chats").child(self.roomUID).child("members").child("\(receiverData["id"] as! String)").child("typing")
        ref.observe(.value, with: { (snapshot) in
            let typing = snapshot.value as? Bool ?? false
            if typing {
                self.navigationItem.titleView = self.setTitleView(typing: true)
            }else{
                self.navigationItem.titleView = self.setTitleView(typing: false)
            }
        })
        
    }
    
    func childAdded(snapshot : DataSnapshot){
        let dict = snapshot.value as? [String : AnyObject] ?? [:]
        if var obj = Mapper<Message>().map(JSONString: dict.toJsonString()) {
            let ref =  Database.database().reference().child("chats").child(self.roomUID).child("members").child(Auth.auth().currentUser!.uid).child("lastSeenMessage")
            obj.id = snapshot.key
            obj.roomId = self.roomUID
            if let index = self.messageList.firstIndex(where: { (item) -> Bool in
                item.messageDate == obj.messageDate && item.type == obj.type && item.sentBy == obj.sentBy
            }){
                self.messageList[index] = obj
                self.tableView.reloadRows(at: [IndexPath.init(row: index, section: 0)], with: .automatic)
                self.setLastSeenMessage(postRef: ref)
            }else{
                if (obj.timestamp < self.time || self.isPause ) && obj.timestamp != 0 {
                    if self.unreadCount == 0 && Auth.auth().currentUser!.uid != obj.sentBy{
                        self.unreadCount += 1
                        self.messageList.append(Message.init(id: snapshot.key, roomId: self.roomUID, sentBy: Auth.auth().currentUser!.uid, message: "1", type: "unread", messageDate: Date().millisecondsSince1970, timestamp: Date().millisecondsSince1970))
                    }else if self.unreadCount != 0 {
                        self.unreadCount += 1
                        self.messageList[self.messageList.count - self.unreadCount] = Message.init(id: snapshot.key, roomId: self.roomUID, sentBy: Auth.auth().currentUser!.uid, message: "\(self.unreadCount)", type: "unread", messageDate: Date().millisecondsSince1970, timestamp: Date().millisecondsSince1970)
                    }
                    self.messageList.append(obj)
                    self.tableView.reloadData()
                    if self.unreadCount < 5 {
                        self.tableView.scrollToBottom()
                    }else{
                        self.tableView.scrollToBottom(count : 5 - self.unreadCount)
                    }
                    self.insertOrUpdateMessage(message: obj)
                }else if obj.timestamp != 0 {
                    self.messageList.append(obj)
                    self.tableView.insertRows(at: [IndexPath.init(row: self.messageList.count - 1, section: 0)], with: .automatic)
                    self.tableView.scrollToBottom()
                    self.removeUnreadCell()
                    self.insertOrUpdateMessage(message: obj)
                }
                self.setLastSeenMessage(postRef: ref)
            }
        }
    }
    
    private func removeUnreadCell(){
        if let unreadIndex = self.messageList.firstIndex(where: { (item) -> Bool in
            item.type == "unread"
        }){
            self.messageList.remove(at: unreadIndex)
            self.tableView.deleteRows(at: [IndexPath.init(row: unreadIndex, section: 0)], with: .automatic)
            self.unreadCount = 0
        }
    }
    
    func createDatabase() {
        let ref = database.child("userChats")
        let ref2 = database.child("chats")
        roomUID = ref.child(Auth.auth().currentUser!.uid).childByAutoId().key!
        ref.child(Auth.auth().currentUser!.uid).child(roomUID).setValue(self.receiverData["id"] as! String)
        ref.child(self.receiverData["id"] as! String).child(roomUID).setValue(Auth.auth().currentUser!.uid)
        ref2.child(roomUID).child("members").child(Auth.auth().currentUser!.uid).setValue("")
        ref2.child(roomUID).child("members").child(self.receiverData["id"] as! String).setValue("")
        self.getMessageList(roomId: self.roomUID)
    }
    
    func setLastSeenMessage(postRef : DatabaseReference){
        postRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            currentData.value = ServerValue.timestamp()
            return TransactionResult.success(withValue: currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        // Get required info out of the notification
        self.gesture = self.viewTouch()
        self.tableView.scrollToBottom()
        if  let userInfo = notification.userInfo, let endValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey], let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey], let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] {
            let keyboardRectangle = (endValue as AnyObject).cgRectValue
            let keyboardHeight = keyboardRectangle!.height
            self.messageViewBottom.constant = -keyboardHeight + itemHeight
            
            let duration = (durationValue as AnyObject).doubleValue
            let options = UIView.AnimationOptions(rawValue: UInt((curveValue as AnyObject).integerValue << 16))
            UIView.animate(withDuration: duration!, delay: 0, options: options, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    @IBAction func toBottomAction(_ sender: Any) {
        self.tableView.scrollToBottom(count: 0, animated: false)
    }
    
    var itemHeight: CGFloat {
        guard #available(iOS 11.0, *),
            let window = UIApplication.shared.keyWindow else {
                return 0.0
        }
        return window.safeAreaInsets.bottom
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.removeGesture(gesture: self.gesture)
        if  let userInfo = notification.userInfo, let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey], let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] {
            
            self.messageViewBottom.constant = 0
            
            let duration = (durationValue as AnyObject).doubleValue
            let options = UIView.AnimationOptions(rawValue: UInt((curveValue as AnyObject).integerValue << 16))
            UIView.animate(withDuration: duration!, delay: 0, options: options, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let pasteboard = UIPasteboard.general
        if pasteboard.hasStrings && pasteboard.strings?.count == 5 && pasteboard.strings?.first == "copy_action_firebasechat"{
            if pasteboard.strings?[2] == "text" {
                textView.text = pasteboard.strings?[1]
                DispatchQueue.main.async{
                    let newPosition = textView.endOfDocument
                    textView.selectedTextRange = textView.textRange(from: newPosition, to: newPosition)
                    self.textViewDidChange(textView)
                }
            }else if pasteboard.strings?[2] == "image"{
                let imageName = pasteboard.strings?[1].split(separator: "|").map(String.init).last ?? ""
                let documentsURL = URL.createFolder(folderName: "Photos")
                let localURL = documentsURL!.appendingPathComponent(imageName)
                self.attachmentImage = UIImage.init(contentsOfFile: localURL.path)!
                self.attachmentFileName = imageName
                self.isMovie = false
                self.isCopy = true
                self.view.endEditing(true)
                self.performSegue(withIdentifier: "imageOrVideo", sender: nil)
            }else if pasteboard.strings?[2] == "location"{
                self.coordinate = pasteboard.strings?[1].split(separator: "|").map(String.init).first ?? ""
                self.view.endEditing(true)
                self.performSegue(withIdentifier: "copyLocation", sender: nil)
            }
            pasteboard.strings = nil
            return false
        }
        
        return true
    }
    
    
    func textViewDidChange(_ textView: UITextView) {
        if self.messageText.numberOfLines <= 5 {
            self.messageTextHeight.constant = self.messageText.contentSize.height
        }
        
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.sendButton.isHidden = true
            self.micButton.isHidden = false
        }else {
            self.micButton.isHidden = true
            self.sendButton.isHidden = false
        }
        
        let ref = self.database.child("chats").child(self.roomUID).child("members").child(Auth.auth().currentUser!.uid).child("typing")
        self.timer?.invalidate()
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || self.roomUID.isEmpty {
            if !self.roomUID.isEmpty {
                ref.setValue(false)
            }
            self.isTyping = false
            return
        }
        self.startTimer()
        
        if !self.isTyping{
            ref.setValue(true)
            self.isTyping = true
        }
    }
    
    
    @IBAction func sendMessage(_ sender: Any) {
        if !self.messageText.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if roomUID.isEmpty {
                self.createDatabase()
            }
            let ref = database.child("chatMessages")
            if self.replyView.isHidden == false && self.replyPosition != -1 {
                let msg = self.messageList[self.replyPosition]
                let last = msg.message.split(separator: "|").last?.trimmingCharacters(in: .whitespaces) ?? ""
                let message = [
                    "sentBy": Auth.auth().currentUser!.uid,
                    "message": "\(msg.sentBy)|\(msg.getMessage)|\(last)|\(msg.type)|\(messageText.text.trimmingCharacters(in: .whitespacesAndNewlines))",
                    "type": "reply",
                    "messageDate": Date().millisecondsSince1970,
                    "timestamp" : ServerValue.timestamp()] as [String : Any]
                let messageUID = ref.childByAutoId().key!
                ref.child(self.roomUID).child(messageUID).setValue(message)
            }else{
                let message = [
                    "sentBy": Auth.auth().currentUser!.uid,
                    "message": messageText.text.trimmingCharacters(in: .whitespacesAndNewlines),
                    "type": "text",
                    "messageDate": Date().millisecondsSince1970,
                    "timestamp" : ServerValue.timestamp()] as [String : Any]
                let messageUID = ref.childByAutoId().key!
                ref.child(self.roomUID).child(messageUID).setValue(message)
            }
            let ref2 = database.child("chats")
            let lastMessageSend = [
                "sentBy": Auth.auth().currentUser!.uid,
                "message": messageText.text.trimmingCharacters(in: .whitespacesAndNewlines),
                "type": "text",
                "date": Date().millisecondsSince1970,
                "timestamp" : ServerValue.timestamp()] as [String : Any]
            ref2.child(roomUID).child("message").setValue(lastMessageSend)
            self.replyClose(self.replyView as Any)
            self.messageText.text = ""
            self.messageTextHeight.constant = 36.0
            self.timer?.invalidate()
            self.timerUpdate()
            self.sendButton.isHidden = true
            self.micButton.isHidden = false
        }
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let nc = segue.destination as? UINavigationController {
            if let vc = nc.topViewController as? ImageOrVideoPreviewViewController {
                vc.attachmentFileName = self.attachmentFileName
                vc.attachmentImage = self.attachmentImage
                vc.attachmentVideoUrl = self.attachmentVideoUrl
                vc.isMovie = self.isMovie
                vc.isCopy = self.isCopy
            }else if let vc = nc.topViewController as? CopyLocationViewController {
                vc.coordinate = self.coordinate
            }else if let vc = nc.topViewController as? ForwardMessageViewController {
                vc.message = self.forwardMessage
            }
        }else if let vc = segue.destination as? MapViewController {
            vc.coordinate = self.coordinate
            vc.username = (Auth.auth().currentUser!.uid == self.sentBy ? "me" : self.receiverData["username"] as? String) ?? ""
        }else if let vc = segue.destination as? ImageViewController {
            if self.segueType == .imageVideo {
                if let indexPath = self.selectedIndexPath{
                    if let cell = self.tableView.cellForRow(at: indexPath) {
                        vc.selectedImage = self.messageList[self.selectedIndexPath.row].message
                        vc.image = (cell.viewWithTag(1) as! UIImageView).image
                    }
                }
            }else if segueType == .profile {
                vc.selectedImage = nil
                vc.image = self.profileImageView.image
                vc.toolbarHidden = true
            }
        }else if let vc = segue.destination as? VideoViewController {
            if let indexPath = self.selectedIndexPath {
                if let cell = self.tableView.cellForRow(at: indexPath) {
                    vc.videoName = self.messageList[self.selectedIndexPath.row].message
                    vc.videoThumb = (cell.viewWithTag(1) as! UIImageView).image
                }
            }
        }
        
    }
    
    var finalPoint : CGPoint!
    
    @IBAction func micTouchDown(_ sender: Any) {
        self.startRecording()
        self.messageText.alpha = 0.0
    }
    
    @IBAction func touchUpInside(_ sender: Any) {
        self.finishRecording()
        self.messageText.alpha = 1.0
        if self.elapsedTime.text != "00:00 - 05:00" && (URL.fileExists(folderName: "Records", fileName: self.attachmentFileName) ?? false) {
            //self.preparePlayer()
            // self.audioPlayer.play()
            self.uploadRecordFile()
        }else{
            let documentsURL = URL.createFolder(folderName: "Records")
            URL.deleteFile(documentPath: documentsURL!.appendingPathComponent(self.attachmentFileName).path)
        }
    }
    
    @IBAction func handlePan(_ sender: UIPanGestureRecognizer) {
        
        let translation = sender.translation(in: view)
        
        // 2
        guard let gestureView = sender.view else {
            return
        }
        
        if sender.state == .began{
            finalPoint = CGPoint( x: gestureView.center.x , y: gestureView.center.y)
        }
        
        if sender.state == .ended{
            self.finishRecording()
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: .curveEaseOut,
                animations: {
                    self.slideToDelete.alpha = 1.0
                    gestureView.center = self.finalPoint
                    self.messageText.alpha = 1.0
            }, completion: { result in
                if self.elapsedTime.text != "00:00 - 05:00" && (URL.fileExists(folderName: "Records", fileName: self.attachmentFileName) ?? false) {
                    self.uploadRecordFile()
                }else{
                    let documentsURL = URL.createFolder(folderName: "Records")
                    URL.deleteFile(documentPath: documentsURL!.appendingPathComponent(self.attachmentFileName).path)
                }
            })
            return
        }
        
        if gestureView.center.x + translation.x > finalPoint.x {
            gestureView.center = self.finalPoint
        }else if gestureView.center.x + translation.x > self.view.frame.width / 2{
            gestureView.center = CGPoint(
                x: gestureView.center.x + translation.x,
                y: gestureView.center.y
            )
            self.slideToDelete.alpha = 1.0 - 2.0 * (self.view.frame.width - gestureView.center.x + translation.x) / self.view.frame.width
            sender.setTranslation(.zero, in: view)
        }else {
            let documentsURL = URL.createFolder(folderName: "Records")
            URL.deleteFile(documentPath: documentsURL!.appendingPathComponent(self.attachmentFileName).path)
            sender.state = .ended
        }
    }
    
    func preparePlayer(fileName : String) {
        var error: NSError?
        do {
            let documentsURL = URL.createFolder(folderName: "Records")
            audioPlayer = try AVAudioPlayer(contentsOf: documentsURL!.appendingPathComponent(fileName))
        } catch let error1 as NSError {
            error = error1
            audioPlayer = nil
        }
        if let err = error {
            print("AVAudioPlayer error: \(err.localizedDescription)")
        } else {
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.volume = 10.0
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.playTimer?.invalidate()
        let cell = self.tableView.cellForRow(at: IndexPath.init(row: self.playedRecordIndex, section: 0))
        let slider = cell?.viewWithTag(1) as? UISlider
        let play = cell?.viewWithTag(4) as? UICustomButton
        slider?.value = 0
        play?.setImage(UIImage.init(systemName: "play.fill"), for: .normal)
        play?.imageName = "play.fill"
    }
    
    func startRecording() {
        self.elapsedTime.text = "00:00 - 05:00"
        let documentsURL = URL.createFolder(folderName: "Records")
        self.attachmentFileName = "\(UUID().uuidString).m4a"
        let audioFilename = documentsURL!.appendingPathComponent(self.attachmentFileName)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.record()
            recordTimer = Timer.scheduledTimer(timeInterval: 0.5, target:self, selector:#selector(self.updateAudioMeter(timer:)), userInfo:nil, repeats:true)
        } catch {
            finishRecording()
        }
    }
    
    @objc func updateAudioMeter(timer: Timer)
    {
        if audioRecorder.isRecording
        {
            if audioRecorder.currentTime <= 300 {
                let min = Int(audioRecorder.currentTime / 60)
                let minEnd = Int((300 - audioRecorder.currentTime) / 60)
                let sec = Int(audioRecorder.currentTime.truncatingRemainder(dividingBy: 60))
                let secEnd = Int((300 - audioRecorder.currentTime).truncatingRemainder(dividingBy: 60))
                self.elapsedTime.text = String(format: "%02d:%02d - %02d:%02d", min, sec, minEnd, secEnd)
                audioRecorder.updateMeters()
            }else{
                finishRecording()
            }
            
        }
    }
    
    
    func finishRecording() {
        recordTimer?.invalidate()
        audioRecorder.stop()
        audioRecorder = nil
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording()
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = self.messageList[indexPath.row].getType
        let cell = tableView.dequeueReusableCell(withIdentifier: type.rawValue, for: indexPath)
        //[NSAttributedString.Key.foregroundColor : UIColor.red ,NSAttributedString.Key.underlineStyle : NSUnderlineStyle.double]
        if type == .TextSender || type == .TextReceiver {
            let message = cell.viewWithTag(1) as? UITextView
            let time = cell.viewWithTag(2) as? UILabel
            message?.text = self.messageList[indexPath.row].message
            time?.text = self.messageList[indexPath.row].timestamp.dateToDate()
        }else if type == .ImageSender || type == .ImageReceiver {
            let image = cell.viewWithTag(1) as? UIImageView
            let time = cell.viewWithTag(2) as? UILabel
            let indicator = cell.viewWithTag(3) as? UIActivityIndicatorView
            time?.text = self.messageList[indexPath.row].timestamp.dateToDate()
            indicator?.isHidden = false
            indicator?.startAnimating()
            if self.messageList[indexPath.row].message.contains("local|") {
                let path = self.messageList[indexPath.row].message[6...]
                image?.image = UIImage.init(contentsOfFile: path)?.thumbImage().square()
            }else{
                if indicator?.isAnimating ?? false{
                    indicator?.stopAnimating()
                }
                let ref = Storage.storage().reference().child("images/thumb_\(self.messageList[indexPath.row].message)")
                
                // image?.sd_setImage(with: ref)
                image?.sd_setImage(with: ref, maxImageSize: 1024 * 1024, placeholderImage: nil, options: .highPriority, context: nil, progress: nil, completion: { (image_, error, type, url) in
                    image?.image = image_?.square()
                })
            }
        }else if type == .VideoSender || type == .VideoReceiver {
            let image = cell.viewWithTag(1) as? UIImageView
            let time = cell.viewWithTag(2) as? UILabel
            let indicator = cell.viewWithTag(3) as? UIActivityIndicatorView
            let play = cell.viewWithTag(4) as? UICustomButton
            play?.addTarget(self, action: #selector(playVideo(sender:)), for: .touchUpInside)
            play?.clickIndex = indexPath.row
            time?.text = self.messageList[indexPath.row].timestamp.dateToDate()
            indicator?.isHidden = false
            indicator?.startAnimating()
            if self.messageList[indexPath.row].message.contains("local|") {
                let path = self.messageList[indexPath.row].message[6...]
                image?.image = URL.init(string: "file://" + path)!.generateThumbnail()?.square()
            }else{
                if indicator?.isAnimating ?? false{
                    indicator?.stopAnimating()
                }
                let ref = Storage.storage().reference().child("videos/thumb_\(self.messageList[indexPath.row].message)")
                //  image?.sd_setImage(with: ref)
                image?.sd_setImage(with: ref, maxImageSize: 1024 * 1024, placeholderImage: nil, options: .highPriority, context: nil, progress: nil, completion: { (image_, error, type, url) in
                    image?.image = image_?.square()
                })
                play?.isHidden = false
            }
        }else if type == .ContactSender || type == .ContactReceiver {
            let contact = cell.viewWithTag(1) as? UILabel
            let time = cell.viewWithTag(2) as? UILabel
            let button = cell.viewWithTag(3) as? UICustomButton
            contact?.text = String(self.messageList[indexPath.row].message.split(separator: "|")[0])
            time?.text = self.messageList[indexPath.row].timestamp.dateToDate()
            button?.clickIndex = indexPath.row
            button?.addTarget(self, action: #selector(callOrSaveContact(sender:)), for: .touchUpInside)
        }else if type == .LocationSender || type == .LocationReceiver {
            let image = cell.viewWithTag(1) as? UIImageView
            let time = cell.viewWithTag(2) as? UILabel
            let pin = cell.viewWithTag(3) as? UIImageView
            time?.text = self.messageList[indexPath.row].timestamp.dateToDate()
            if self.messageList[indexPath.row].message.contains("local|") {
                let message = self.messageList[indexPath.row].message
                image?.image = (message.split(separator: "|").last?.trimmingCharacters(in: .whitespaces) ?? "").convertBase64ToImage()
                pin?.isHidden = false
            }else{
                let message = self.messageList[indexPath.row].message.split(separator: "|")
                let ref = Storage.storage().reference().child(String(message[1]))
                image?.sd_setImage(with: ref)
                
                pin?.isHidden = false
            }
        }else if type == .RecordSender || type == .RecordReceiver {
            let slider = cell.viewWithTag(1) as? UISlider
            let time = cell.viewWithTag(2) as? UILabel
            let duration = cell.viewWithTag(3) as? UILabel
            let play = cell.viewWithTag(4) as? UICustomButton
            let indicator = cell.viewWithTag(5) as? UIActivityIndicatorView
            time?.text = self.messageList[indexPath.row].timestamp.dateToDate()
            let user = Auth.auth().currentUser!.uid == self.messageList[indexPath.row].sentBy
            slider!.smallerThumb(user: user)
            indicator?.isHidden = false
            indicator?.startAnimating()
            play?.clickIndex = indexPath.row
            play?.imageName = "play.fill"
            play?.addTarget(self, action: #selector(playRecord(sender:)), for: .touchUpInside)
            if self.messageList[indexPath.row].message.contains("local|") {
                let durationSeconds = self.messageList[indexPath.row].message.split(separator: "|")[1]
                duration?.text = Int(durationSeconds)?.getTime()
            }else{
                let message = self.messageList[indexPath.row].message.split(separator: "|")
                slider?.maximumValue = (Float.init(message[0]) ?? 0) * Float.init(1000)
                duration?.text = Int(message[0])?.getTime()
                if indicator?.isAnimating ?? false{
                    indicator?.stopAnimating()
                }
                play?.isHidden = false
            }
            
        }else if type == .ReplySender || type == .ReplyReceiver {
            let message = cell.viewWithTag(1) as? UILabel
            let time = cell.viewWithTag(2) as? UILabel
            let sender = cell.viewWithTag(3) as? UILabel
            let reply = cell.viewWithTag(4) as? UILabel
            let image = cell.viewWithTag(5) as? UIImageView
            let marker = cell.viewWithTag(6) as? UIImageView
            time?.text = self.messageList[indexPath.row].timestamp.dateToDate()
            let messag = self.messageList[indexPath.row].message.split(separator: "|")
            reply?.text = String(messag[1])
            message?.text = String(messag[messag.count - 1])
            image?.image = nil
            if (messag[3] == "video" || messag[3] == "image" || messag[3] == "location") {
                let folder =  (messag[3] == "location") ? "" : "\(messag[3])s/thumb_"
                let ref = Storage.storage().reference().child( folder + messag[2])
                let transformer = SDImageResizingTransformer(size: CGSize(width: 50, height: 50), scaleMode: .aspectFill)
                image?.sd_setImage(with: ref, maxImageSize: 1024 * 1024, placeholderImage: nil, options: .lowPriority, context: [.imageTransformer: transformer], progress: nil, completion: nil)
                // image?.sd_setImage(with: ref)
                marker?.isHidden  = (messag[3] == "location") ? false : true
            }else{
                image?.image = nil
            }
            
            let isMe = messag[0] == Auth.auth().currentUser!.uid
            sender?.text = isMe ? "You" : self.receiverData["username"] as! String
            sender?.textColor = isMe ? Constants.contact5 : Constants.contact4
        }else if type == .Unread {
            let message = cell.viewWithTag(1) as? UILabel
            let text = Int.init(self.messageList[indexPath.row].message) ?? 0 > 1 ? "UNREAD MESSAGES" : "UNREAD MESSAGE"
            message?.text = "\(self.messageList[indexPath.row].message) \(text)"
        }
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let closeAction = UIContextualAction(style: .normal, title:  nil, handler: { (ac:UIContextualAction, view:UIView, success:(Bool) -> Void) in
            let isMe = self.messageList[indexPath.row].sentBy == Auth.auth().currentUser!.uid
            self.replySender.text =  (isMe) ? "You" : self.receiverData["username"] as? String ?? ""
            self.replyMessage.text = self.messageList[indexPath.row].getMessage
            self.replyLine.backgroundColor = isMe ? Constants.contact5 : Constants.contact4
            self.replySender.textColor = isMe ? Constants.contact5 : Constants.contact4
            self.replyMarker.isHidden = true
            self.replyThumb.image = nil
            self.replyPosition = indexPath.row
            switch self.messageList[indexPath.row].type {
            case "video" :
                let cell = tableView.cellForRow(at: indexPath)
                let image = cell?.viewWithTag(1) as? UIImageView
                self.replyThumb.image = image?.image
                break
            case "image" :
                let cell = tableView.cellForRow(at: indexPath)
                let image = cell?.viewWithTag(1) as? UIImageView
                self.replyThumb.image = image?.image
                break
            case "location" :
                let cell = tableView.cellForRow(at: indexPath)
                let image = cell?.viewWithTag(1) as? UIImageView
                self.replyThumb.image = image?.image
                self.replyMarker.isHidden = false
                break
            default:
                break
            }
            self.replyView.isHidden = false
            self.tableViewBottom.constant = 61
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                self.view.layoutIfNeeded()
                //self.tableView.scrollToBottom()
            }, completion: nil)
            success(true)
        })
        closeAction.image = UIImage.init(systemName: "arrowshape.turn.up.left.circle.fill")?.sd_tintedImage(with: .gray)
        closeAction.backgroundColor = .white
        return UISwipeActionsConfiguration(actions: [closeAction])
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.messageList[indexPath.row].type == "location"{
            self.segueType = .none
            self.coordinate = String(self.messageList[indexPath.row].message.split(separator: "|")[0])
            self.sentBy = self.messageList[indexPath.row].sentBy
            self.performSegue(withIdentifier: "mapView", sender: nil)
        }else if self.messageList[indexPath.row].type == "image"{
            self.segueType = .imageVideo
            self.selectedIndexPath = indexPath
            let cell = self.tableView.cellForRow(at: indexPath)
            let ref = Storage.storage().reference().child("images/thumb_\(self.messageList[indexPath.row].message)")
            (cell?.viewWithTag(1) as! UIImageView).sd_setImage(with: ref)
            self.performSegue(withIdentifier: "image", sender: nil)
        }
    }
    
    @objc func callOrSaveContact(sender: UICustomButton){
        let clickIndex = sender.clickIndex
        if self.messageList[clickIndex].getType == .ContactSender {
            let message = self.messageList[clickIndex].message.split(separator: "|").map(String.init)
            if let phoneCallURL = URL(string: "tel://\(String(describing: message.last!))"), UIApplication.shared.canOpenURL(phoneCallURL)
            {
                UIApplication.shared.open(phoneCallURL, options: [:], completionHandler: nil)
            }
        }else{
            let message = self.messageList[clickIndex].message.split(separator: "|").map(String.init)
            self.addPhoneNumber(name: message.first ?? "", phNo: message.last ?? "")
        }
    }
    
    @objc func playVideo(sender: UICustomButton){
        let clickIndex = sender.clickIndex
        self.selectedIndexPath = IndexPath.init(item: clickIndex, section: 0)
        let cell = self.tableView.cellForRow(at: self.selectedIndexPath)
        let indicator = cell?.viewWithTag(3) as? UIActivityIndicatorView
        if let videoToLoad = self.messageList[clickIndex].message as? String{
            let ref = Storage.storage().reference().child("videos")
            ref.loadVideo(indicator: indicator!, fileName: videoToLoad, completion: { result in
                self.segueType = .imageVideo
                let documentsURL = URL.createFolder(folderName: "Videos")
                let localURL = documentsURL!.appendingPathComponent(result)
                (cell?.viewWithTag(1) as! UIImageView).image = URL.init(string: "file://" + localURL.path)!.generateThumbnail(original: true)
                self.performSegue(withIdentifier: "video", sender: nil)
            })
        }
        
    }
    
    @objc func playRecord(sender: UICustomButton){
        let clickIndex = sender.clickIndex
        let fileName = self.messageList[clickIndex].message.split(separator: "|").last?.trimmingCharacters(in: .whitespaces)[8...] ?? ""
        if self.playedRecordIndex == -1 || self.playedRecordIndex == clickIndex {
            let bool = self.playedRecordIndex != -1
            self.playedRecordIndex = clickIndex
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: self.playedRecordIndex, section: 0))
            self.playedSlider = cell?.viewWithTag(1) as? UISlider
            let indicator = cell?.viewWithTag(5) as? UIActivityIndicatorView
            Storage.storage().reference().child("records").loadAudio(indicator: indicator!, fileName : fileName, completion: {result in
                self.player(sender: sender, fileName: result, bool : bool)
            })
        }else{
            let cell = self.tableView.cellForRow(at: IndexPath.init(row: self.playedRecordIndex, section: 0))
            let slider = cell?.viewWithTag(1) as? UISlider
            let play = cell?.viewWithTag(4) as? UICustomButton
            slider?.value = 0
            play?.setImage(UIImage.init(systemName: "play.fill"), for: .normal)
            play?.imageName = "play.fill"
            self.playedRecordIndex = clickIndex
            let cell2 = self.tableView.cellForRow(at: IndexPath.init(row: self.playedRecordIndex, section: 0))
            self.playedSlider = cell2?.viewWithTag(1) as? UISlider
            let indicator = cell2?.viewWithTag(5) as? UIActivityIndicatorView
            Storage.storage().reference().child("records").loadAudio(indicator: indicator!,fileName : fileName, completion: {result in
                self.player(sender: sender, fileName: result, bool : false)
            })
        }
        
    }
    
    func player(sender: UICustomButton, fileName : String, bool : Bool){
        if self.audioPlayer != nil && self.audioPlayer.isPlaying {
            self.audioPlayer.stop()
            playTimer?.invalidate()
        }
        if !bool {
            self.preparePlayer(fileName: fileName)
        }
        
        if sender.imageName == "play.fill"{
            sender.setImage(UIImage.init(systemName: "pause.fill"), for: .normal)
            sender.imageName = "pause.fill"
            self.audioPlayer.play()
            self.playTimer = Timer.scheduledTimer(timeInterval: 0.01, target:self, selector:#selector(self.updateSlider(timer:)), userInfo:nil, repeats:true)
        }else{
            sender.setImage(UIImage.init(systemName: "play.fill"), for: .normal)
            sender.imageName = "play.fill"
            self.audioPlayer.stop()
            self.playTimer?.invalidate()
        }
        
    }
    
    @objc func updateSlider(timer: Timer){
        self.playedSlider.value = Float(self.audioPlayer.currentTime * 1000)
    }
    
    func uploadRecordFile(){
        let documentsURL = URL.createFolder(folderName: "Records")
        let audioAsset = AVURLAsset.init(url: documentsURL!.appendingPathComponent(self.attachmentFileName), options: nil)
        let duration = audioAsset.duration
        let durationInSeconds = Int(CMTimeGetSeconds(duration))
        let filePath = documentsURL!.appendingPathComponent(self.attachmentFileName).path
        let date = Date().millisecondsSince1970
        self.messageList.append(Message.init(id: "", roomId: self.roomUID, sentBy: Auth.auth().currentUser!.uid, message: "local|\(durationInSeconds)|records/\(self.attachmentFileName)", type: "record", messageDate: date , timestamp: date))
        self.tableView.insertRows(at: [IndexPath.init(row: self.messageList.count - 1, section: 0)], with: .automatic)
        self.tableView.scrollToBottom()
        let file = URL.init(string: "file://" + filePath)
        let fileRef = Storage.storage().reference().child("records/\(self.attachmentFileName)")
        let _ = fileRef.putFile(from: file!, metadata: nil) { (metadata, error) in
            guard let _ = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            self.sendMessageToFirebase(message: "\(durationInSeconds)|records/\(self.attachmentFileName)", lastMessage: "🎙 \(durationInSeconds.getTime())", type: "record", date: date)
        }
    }
    
    @objc func uploadFile(_ notification: NSNotification) {
        if let filePath = notification.userInfo?["filePath"] as? String {
            let fileFolder = self.isMovie ? "videos/" : "images/"
            let type = self.isMovie ? "video" : "image"
            let fileRef = Storage.storage().reference().child("\(fileFolder)\(self.attachmentFileName)")
            let fileThumbRef = Storage.storage().reference().child("\(fileFolder)thumb_\(self.attachmentFileName)")
            let file = self.isMovie ? (NSData(contentsOf: URL.init(string: "file://" + filePath)!) as Data?) : UIImage.init(contentsOfFile: filePath)!.jpegData(compressionQuality: 1.0)!
            let thumb =  self.isMovie ?  URL.init(string: "file://" + filePath)!.generateThumbnail()!.jpegData(compressionQuality: 1.0)! : UIImage.init(contentsOfFile: filePath)!.thumbImage().jpegData(compressionQuality: 1.0)!
            let date = Date().millisecondsSince1970
            self.messageList.append(Message.init(id: "", roomId: self.roomUID, sentBy: Auth.auth().currentUser!.uid, message: "local|\(filePath)", type: type, messageDate: date , timestamp: date))
            self.tableView.insertRows(at: [IndexPath.init(row: self.messageList.count - 1, section: 0)], with: .automatic)
            self.tableView.scrollToBottom()
            let metadataFile = StorageMetadata()
            metadataFile.contentType = self.isMovie ? "video/mp4" : "image/jpeg"
            let metadataThumb = StorageMetadata()
            metadataThumb.contentType = "image/jpeg"
            let _ = fileThumbRef.putData(thumb, metadata: metadataThumb) { (metadata, error) in
                guard let _ = metadata else {
                    // Uh-oh, an error occurred!
                    return
                }
                let _ = fileRef.putData(file!, metadata: metadataFile) { (metadata2, error) in
                    guard let _ = metadata2 else {
                        // Uh-oh, an error occurred!
                        return
                    }
                    self.sendMessageToFirebase(message: "\(self.attachmentFileName)", lastMessage: "\(fileFolder)\(self.attachmentFileName)", type: type, date: date)
                }
            }
        }
    }
    
    
    func uploadFileFromGallery(_ filePath : String) {
        let fileFolder = self.isMovie ? "videos/" : "images/"
        let type = self.isMovie ? "video" : "image"
        let fileRef = Storage.storage().reference().child("\(fileFolder)\(self.attachmentFileName)")
        let fileThumbRef = Storage.storage().reference().child("\(fileFolder)thumb_\(self.attachmentFileName)")
        let file = self.isMovie ? (NSData(contentsOf: URL.init(string: "file://" + filePath)!) as Data?) : UIImage.init(contentsOfFile: filePath)!.jpegData(compressionQuality: 1.0)!
        let thumb =  self.isMovie ?  URL.init(string: "file://" + filePath)!.generateThumbnail()!.jpegData(compressionQuality: 1.0)! : UIImage.init(contentsOfFile: filePath)!.thumbImage().jpegData(compressionQuality: 1.0)!
        let date = Date().millisecondsSince1970
        self.messageList.append(Message.init(id: "", roomId: self.roomUID, sentBy: Auth.auth().currentUser!.uid, message: "local|\(filePath)", type: type, messageDate: date , timestamp: date))
        self.tableView.insertRows(at: [IndexPath.init(row: self.messageList.count - 1, section: 0)], with: .automatic)
        self.tableView.scrollToBottom()
        let metadataFile = StorageMetadata()
        metadataFile.contentType = self.isMovie ? "video/mp4" : "image/jpeg"
        let metadataThumb = StorageMetadata()
        metadataThumb.contentType = "image/jpeg"
        let _ = fileThumbRef.putData(thumb, metadata: metadataThumb) { (metadata, error) in
            guard let _ = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            let _ = fileRef.putData(file!, metadata: metadataFile) { (metadata2, error) in
                guard let _ = metadata2 else {
                    // Uh-oh, an error occurred!
                    return
                }
                self.sendMessageToFirebase(message: "\(self.attachmentFileName)", lastMessage: "\(fileFolder)\(self.attachmentFileName)", type: type, date: date)
            }
        }
    }
    
    @objc func shareLocation(_ notification: NSNotification) {
        if let mapImage = notification.userInfo?["image"] as? UIImage {
            let coordinate = notification.userInfo?["coordinate"] as? String ?? ""
            let filePath = "maps/\(UUID().uuidString)"
            let fileRef = Storage.storage().reference().child(filePath)
            let file = mapImage.jpegData(compressionQuality: 1.0)!
            let base64 = file.base64EncodedString()
            let date = Date().millisecondsSince1970
            self.messageList.append(Message.init(id: "", roomId: self.roomUID, sentBy: Auth.auth().currentUser!.uid, message: "local|\(String(describing: coordinate))|\(base64)", type: "location", messageDate: date , timestamp: date))
            self.tableView.insertRows(at: [IndexPath.init(row: self.messageList.count - 1, section: 0)], with: .automatic)
            self.tableView.scrollToBottom()
            let metadataFile = StorageMetadata()
            metadataFile.contentType = "image/jpeg"
            let _ = fileRef.putData(file, metadata: metadataFile) { (metadata, error) in
                guard let _ = metadata else {
                    // Uh-oh, an error occurred!
                    return
                }
                self.sendMessageToFirebase(message: "\(String(describing: coordinate))|\(filePath)", lastMessage: "📍 Location", type: "location", date: date)
            }
        }
    }
    
    @objc func shareContact(_ notification: NSNotification) {
        if let name = notification.userInfo?["name"] as? String {
            let phoneNumber = (notification.userInfo?["phoneNumber"] as? String) ?? ""
            self.sendMessageToFirebase(message: "\(name)|\(phoneNumber)", lastMessage: "👤 \(name)", type: "contact")
        }
    }
    
    func sendMessageToFirebase(message : String, lastMessage : String, type :String, date : Int64 = Date().millisecondsSince1970){
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
    }
    
    func makeContextMenu(copyVisible : Bool = false, message: Message? = nil) -> UIMenu {
        self.removeUnreadCell()
        let forward = UIAction(title: "Forward", image: UIImage(systemName: "arrowshape.turn.up.right.fill")) { action in
            self.forwardMessage = message
            self.performSegue(withIdentifier: "forwardMessage", sender: nil)
        }
        
        let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc.fill")) { action in
            UIPasteboard.general.strings = ["copy_action_firebasechat", message?.message ?? "", message?.type ?? "" , message?.sentBy ?? "", message?.messageDate.dateToDate() ?? ""]
        }
        
        let delete = UIAction(title: "Delete", image: UIImage(systemName: "trash.fill")) { action in
            if let index = self.messageList.firstIndex(where: { (item) -> Bool in
                item.id == message?.id
            }){
                self.deleteMessage(message: message!)
                self.messageList.remove(at: index)
                self.tableView.deleteRows(at: [IndexPath.init(row: index, section: 0)], with: .left)
                self.updateLastMessage(id: self.roomUID, message: self.messageList.count > 0 ? self.messageList.last!.getMessage : "", type: self.messageList.count > 0 ? self.messageList.last!.type : "text")
            }
        }
        
        return UIMenu(title: "", children: copyVisible ? [forward,copy,delete] : [forward,delete])
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: String(indexPath.row) as NSCopying, previewProvider: nil, actionProvider: { suggestedActions in
            if self.messageList[indexPath.row].getType != .Unread {
                return self.makeContextMenu(copyVisible: self.messageList[indexPath.row].copyVisible, message: self.messageList[indexPath.row])
            }else{
                return nil
            }
            
        })
    }
    
    func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        guard
            let identifier = configuration.identifier as? String,
            let index = Int(identifier),
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)),
            self.messageList[index].getType != .Unread
            else {
                return nil
        }
        
        if let superView = (cell.viewWithTag(2) as! UILabel).superview {
            let parameters = UIPreviewParameters()
            parameters.backgroundColor = self.messageList[index].getType.rawValue.contains("Sender") ? Constants.colorSender : Constants.colorReceiver
            return UITargetedPreview(view: superView , parameters: parameters)
        }else{
            return nil
        }
    }
    
}



extension RoomViewController: ZoomingViewController{
    func zoomingImageView(for transition: ZoomTransitioningDelegate) -> UIImageView? {
        if self.segueType == .imageVideo {
            if let indexPath = selectedIndexPath {
                let cell = self.tableView.cellForRow(at: indexPath)
                return cell?.viewWithTag(1) as? UIImageView
            }else{
                return nil
            }
        }else if self.segueType == .profile{
            return self.profileImageView
        }else{
            return nil
        }
    }
    
    func zoomingBackgroundView(for transition: ZoomTransitioningDelegate) -> UIView? {
        return nil
    }
    
    func zoomingType(for transition: ZoomTransitioningDelegate) -> Constants.SegueType? {
        return self.segueType
    }
}

extension RoomViewController: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: { suggestedActions in
            
            return self.makeContextMenu()
        })
    }
}

