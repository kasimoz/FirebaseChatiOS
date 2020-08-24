//
//  NewChatViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 17.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import ObjectMapper

class NewChatViewController: UITableViewController {
    
    var users = [User]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        
        self.users = self.convertToUserArray(items: self.retrieveUsers() ?? [])
        self.tableView.reloadData()
        let ref = Database.database().reference()
        ref.child("users").queryOrdered(byChild: "username").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
            for child in snapshot.children.allObjects as! [DataSnapshot] {
                if var user = Mapper<User>().map(JSONString: (child.value as! Dictionary<String, AnyObject>).toJsonString()) {
                    user.id = child.key
                    if child.key != Auth.auth().currentUser?.uid {
                        if let index = self.users.firstIndex(where: { (item) -> Bool in
                            item.id == user.id
                        }) {
                            self.users[index] = user
                        }else{
                            self.users.append(user)
                        }
                        
                    }
                }
            }
            self.tableView.reloadData()
            for user in self.users {
                self.insertOrUpdateUser(user: user)
            }
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
        let receiverData : [String: Any] = self.users[indexPath.row].toJSON()
        NotificationCenter.default.post(name: Notification.Name("NewChat"), object: nil, userInfo: receiverData)
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
