//
//  ForwardMessageViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 2.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import ObjectMapper

class ForwardMessageViewController: UITableViewController {
    var message : Message!
    var users = [User]()
    var database = Database.database().reference()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let ref = Database.database().reference()
        ref.child("users").queryOrdered(byChild: "username").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if var user = Mapper<User>().map(JSONString: (child.value as! Dictionary<String, AnyObject>).toJsonString()) {
                    if child.key != Auth.auth().currentUser?.uid {
                        user.id = child.key
                        self.users.append(user)
                    }
                }
            }
            self.tableView.reloadData()
        })
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationMessage(_:)), name: NSNotification.Name("notification"), object: nil)
        
    }
    
    @objc func notificationMessage(_ notification: NSNotification) {
        if let _ = notification.userInfo?["sender"] as? String {
            if let _ = notification.userInfo?["chatUID"] as? String {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func createDatabase(index: Int, completion: @escaping (_ result: String?)->()) {
        self.roomUID(index: index, completion: { id in
            if id != nil {
                completion(id!)
            }else{
                let ref = self.database.child("userChats")
                let ref2 = self.database.child("chats")
                let roomUID = ref.child(Auth.auth().currentUser!.uid).childByAutoId().key!
                ref.child(Auth.auth().currentUser!.uid).child(roomUID).setValue(self.users[index].id)
                ref.child(self.users[index].id).child(roomUID).setValue(Auth.auth().currentUser!.uid)
                ref2.child(roomUID).child("members").child(Auth.auth().currentUser!.uid).setValue("")
                ref2.child(roomUID).child("members").child(self.users[index].id).setValue("")
                completion(roomUID)
            }
        })
    }
    
    func roomUID(index : Int, completion: @escaping (_ result: String?)->()) {
        let ref = database.child("userChats")
        ref.child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if child.value as? String == self.users[index].id {
                    completion(child.key)
                }
            }
        })
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.users.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let image = cell.viewWithTag(10) as? UIImageView
        let username = cell.viewWithTag(1) as? UILabel
        let status = cell.viewWithTag(2) as? UILabel
        
        
        username?.text = users[indexPath.row].username
        status?.text = users[indexPath.row].status
        
        let ref = Storage.storage().reference().child("images/\(users[indexPath.row].image)")
        image?.sd_setImage(with: ref, placeholderImage: UIImage.init(systemName: "person.crop.circle.fill"))
        image?.setRounded()
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.createDatabase(index: indexPath.row, completion: { id in
            let ref = self.database.child("chatMessages")
            let ref2 = self.database.child("chats")
            let date = Date().millisecondsSince1970
            let message = [
                "sentBy": Auth.auth().currentUser!.uid,
                "message": self.message.message,
                "type": self.message.type,
                "messageDate": date,
                "timestamp" : ServerValue.timestamp()] as [String : Any]
            let messageUID = ref.childByAutoId().key!
            ref.child(id!).child(messageUID).setValue(message)
            let lastMessageSend = [
                "sentBy": Auth.auth().currentUser!.uid,
                "message": self.message.getMessage,
                "type": self.message.type,
                "date": date,
                "timestamp" : ServerValue.timestamp()] as [String : Any]
            ref2.child(id!).child("message").setValue(lastMessageSend)
            self.dismiss(animated: true, completion: nil)
        })
        
    }
    
}
