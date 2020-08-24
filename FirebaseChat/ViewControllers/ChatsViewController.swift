//
//  ChatsViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 16.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import Firebase
import ObjectMapper
import FirebaseUI

class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    @IBOutlet weak var tableView: UITableView!
    var ref: DatabaseReference!
    var chatDict : [String : AnyObject]!
    var chats = [ChatUserMessage]()
    var receiverData : [String: Any]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let accessGroup = "group.firebaseChat.share"
        do {
            try Auth.auth().useUserAccessGroup(accessGroup)
        } catch let error as NSError {
            print("Error changing user access group: %@", error)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.pushNewChat(_:)), name: NSNotification.Name("NewChat"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.newChatAction(_:)), name: NSNotification.Name("shortcut"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.removeCounter(_:)), name: NSNotification.Name("removeCounter"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationMessage(_:)), name: NSNotification.Name("notification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reachable(_:)), name: NSNotification.Name("reachable"), object: nil)
        //self.resetAllCoreData()
        self.chats = self.convertToChatUserMessageArray(items: self.retrieveChats() ?? [])
        self.tableView.reloadData()
        self.ref = Database.database().reference()
        self.ref.child("userChats").child(Auth.auth().currentUser!.uid).observe(DataEventType.value, with: { (snapshot) in
            self.chatDict = snapshot.value as? [String : AnyObject] ?? [:]
            for (key, value) in self.chatDict{
                let ref2 = Database.database().reference().child("chats")
                ref2.child(key).child("message").removeAllObservers()
                ref2.child(key).child("message").observe(DataEventType.value, with: { (snapshot) in
                    let dict = snapshot.value as? [String : AnyObject] ?? [:]
                    var lastMessage = Mapper<LastMessage>().map(JSONString: dict.toJsonString())
                    let chatId = snapshot.ref.parent?.ref.key!
                    lastMessage?.id = chatId!
                    let message = lastMessage?.message
                    let date = lastMessage?.date
                    let type = lastMessage?.type
                    let sentBy = lastMessage?.sentBy
                    let timestamp = lastMessage?.timestamp
                    let ref3 = Database.database().reference().child("users")
                    if message == nil {
                        return
                    }
                    if let index = self.chats.firstIndex(where: { (item) -> Bool in
                        item.chat?.roomId == chatId
                    }) {
                        if sentBy != Auth.auth().currentUser!.uid && timestamp != self.chats[index].lastMessage?.timestamp{
                            let count = self.chats[index].chat?.count == nil ? 0 : (self.chats[index].chat?.count)! + 1
                            self.chats[index].chat?.count = count
                        }
                        
                        if timestamp != self.chats[index].lastMessage?.timestamp {
                            self.chats[index].lastMessage?.message = message ?? ""
                            self.chats[index].lastMessage?.date = date ?? 0
                            self.chats[index].lastMessage?.sentBy = sentBy ?? ""
                            self.chats[index].lastMessage?.type = type ?? ""
                            self.chats[index].lastMessage?.timestamp = timestamp ?? 0
                        }
                        
                        let item = self.chats[index]
                        self.chats.remove(at: index)
                        self.chats.insert(item, at: 0)
                        self.chats.sort(by: { (first: ChatUserMessage, second: ChatUserMessage) -> Bool in
                            Date.init(milliseconds: Int64(first.lastMessage?.timestamp ?? 0)) > Date.init(milliseconds: Int64(second.lastMessage?.timestamp ?? 0))
                        })
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                            self.tableView.reloadData()
                            self.insertOrUpdateLastMessage(lastMessage: self.chats[index].lastMessage!)
                        })
                    }else{
                        ref3.child((self.chatDict[chatId!]) as! String).observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                            let dict = snapshot.value as? [String : AnyObject] ?? [:]
                            var user = Mapper<User>().map(JSONString: dict.toJsonString())
                            user?.id = snapshot.key
                            let lastMessage = LastMessage.init(id: chatId!, sentBy: sentBy!, message: message!, type: type!, date: date!, timestamp: timestamp!)
                            
                            
                            let main = Chats.init(id: UUID().uuidString, roomId: chatId!, userId: snapshot.key, count: 1)
                            let chat = ChatUserMessage(main, user: user!, lastMessage: lastMessage)
                            self.chats.append(chat)
                            self.chats.sort(by: { (first: ChatUserMessage, second: ChatUserMessage) -> Bool in
                                Date.init(milliseconds: Int64(first.lastMessage?.timestamp ?? 0)) > Date.init(milliseconds: Int64(second.lastMessage?.timestamp ?? 0))
                            })
                            self.tableView.reloadData()
                            self.deleteUser(user: user!)
                            self.createChat(chats: main, user: user!, lastMessage: lastMessage)
                        })
                    }
                })
            }
        })
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_ :)))
        self.tableView.addGestureRecognizer(longPress)
        
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let result = result {
                //print("Remote instance ID token: \(result.token)")
                self.ref.child("users").child(Auth.auth().currentUser!.uid).child("token").setValue(result.token)
                self.ref.child("users").child(Auth.auth().currentUser!.uid).child("device").setValue("iOS")
            }
        }
    }
    
    @objc func reachable(_ notification: NSNotification) {
        let result = (notification.userInfo?["reachable"] as? Bool) ?? false
        if result {
            self.navigationItem.titleView = nil
        }else{
            self.navigationItem.titleView = self.setNetwokView()
        }
    }
    
    @objc func notificationMessage(_ notification: NSNotification) {
        if let sender = notification.userInfo?["sender"] as? String {
            if let chatUID = notification.userInfo?["chatUID"] as? String {
                if let index = self.chats.firstIndex(where: { (item) -> Bool in
                    item.user?.id == sender
                }) {
                    self.navigationController?.popToRootViewController(animated: false)
                    self.tabBarController?.selectedIndex = 0
                    self.receiverData = self.chats[index].user?.toJSON()
                    self.receiverData["roomId"] =  chatUID
                    self.performSegue(withIdentifier: "room", sender: nil)
                }
            }
        }
    }
    
    @objc func handleLongPress(_ gesture : UILongPressGestureRecognizer!) {
        if gesture.state != .ended {
            return
        }
        let p = gesture.location(in: self.tableView)
        
        if let indexPath = self.tableView.indexPathForRow(at: p){
            //let cell = self.collectionView.cellForItem(at: indexPath)
            self.deleteRoom(id: self.chats[indexPath.row].chat!.roomId)
            self.deleteChat(chat: self.chats[indexPath.row].chat!)
            self.deleteLastMessage(message: self.chats[indexPath.row].lastMessage!)
            self.chats.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .left)
        } else {
            print("couldn't find index path")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let image = cell?.viewWithTag(10) as? UIImageView
        let username = cell?.viewWithTag(1) as? UILabel
        let message = cell?.viewWithTag(2) as? UILabel
        let date = cell?.viewWithTag(3) as? UILabel
        let counterView = cell?.viewWithTag(4)
        let counter = cell?.viewWithTag(5) as? UILabel
        counterView!.setRounded()
        
        username?.text = chats[indexPath.row].user?.username
        message?.text = chats[indexPath.row].lastMessage?.getMessage
        date?.text = chats[indexPath.row].lastMessage?.timestamp.dateToDate()
        if(chats[indexPath.row].user?.image == Constants.pImage ){
            image?.image = UIImage.init(systemName: "person.crop.circle.fill")
        }else{
            let ref = Storage.storage().reference().child("images/\(chats[indexPath.row].user?.image ?? "")")
            image?.sd_setImage(with: ref, placeholderImage: UIImage.init(systemName: "person.crop.circle.fill"))
            image?.setRounded()
        }
        counter?.text = String(chats[indexPath.row].chat?.count ?? 0)
        if(chats[indexPath.row].chat?.count ?? 0) == 0 {
            counterView?.isHidden = true
        }else{
            counterView?.isHidden = false
        }
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.receiverData = self.chats[indexPath.row].user?.toJSON()
        if let chat = self.retrieveChat(userId: self.chats[indexPath.row].chat?.userId ?? ""){
            self.receiverData["roomId"] = chat.roomId ?? ""
        }
        self.performSegue(withIdentifier: "room", sender: nil)
    }
    
    @IBAction func newChatAction(_ sender: Any) {
        self.performSegue(withIdentifier: "newChat", sender: nil)
    }
    
    
    @objc func pushNewChat(_ notification: NSNotification) {
        if let _ = notification.userInfo?["username"] as? String {
            self.receiverData = notification.userInfo as? [String: Any]
            if let chat = self.retrieveChat(userId: self.receiverData["id"] as? String ?? "" ){
                self.receiverData["roomId"] = chat.roomId ?? ""
            }
            self.performSegue(withIdentifier: "room", sender: nil)
        }
    }
    
    @objc func removeCounter(_ notification: NSNotification) {
        if let roomId = notification.userInfo?["roomId"] as? String {
            if let index = self.chats.firstIndex(where: { (item) -> Bool in
                item.chat?.roomId == roomId
            }) {
                self.updateCount(roomId: roomId, count: 0)
                self.chats[index].chat?.count = 0
                self.chats[index].lastMessage = Mapper<LastMessage>().map(JSONString: (self.retrieveLastMessage(id: roomId)?.convertToDict().toJsonString())!)
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? RoomViewController {
            vc.receiverData = self.receiverData
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let center = UNUserNotificationCenter.current()
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }
    
    
}
