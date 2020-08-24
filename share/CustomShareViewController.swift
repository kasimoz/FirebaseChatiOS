//
//  CustomShareViewController.swift
//  share
//
//  Created by KasimOzdemir on 11.08.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import Firebase
import ObjectMapper
import FirebaseUI
import CoreData

class CustomShareViewController: UITableViewController {
    var receiverData : [String: Any]!
    var users = [User]()
    override func viewDidLoad() {
        super.viewDidLoad()
        if let _ = FirebaseApp.app() {} else {
            FirebaseApp.configure()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let accessGroup = "group.firebaseChat.share"
        var tempUser: FirebaseAuth.User?
        do {
            try tempUser = Auth.auth().getStoredUser(forAccessGroup: accessGroup)
        } catch let error as NSError {
            print("Error getting stored user: %@", error)
        }
        if tempUser != nil {
            // A user exists in the access group
            /*DispatchQueue.main.async {
                
            }*/
            self.users = self.convertToUserArray(items: self.retrieveUserList() ?? [])
            self.tableView.reloadData()
            let ref = Database.database().reference()
            ref.child("users").queryOrdered(byChild: "username").observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                for child in snapshot.children.allObjects as! [DataSnapshot] {
                    if var user = Mapper<User>().map(JSONString: (child.value as! Dictionary<String, AnyObject>).toJsonString()) {
                        user.id = child.key
                        if child.key != tempUser?.uid {
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
                do {
                    try Auth.auth().useUserAccessGroup(accessGroup)
                } catch let error as NSError {
                    print("Error changing user access group: %@", error)
                }
                self.tableView.reloadData()
            })
        } else {
            // No user exists in the access group
        }
    }
    
    
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = CustomPersistentContainer(name: "ChatDatabase")
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    func retrieveUserList() -> [UserEntity]? {
        
        //We need to create a context from this container
        let managedContext = self.persistentContainer.viewContext
        
        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserEntity")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "username", ascending: true)]
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            return result as? [UserEntity]
        } catch {
            print("Failed")
            return []
        }
    }
    
    func retrieveChat(userId : String) -> ChatEntity? {
        
        //We need to create a context from this container
        let managedContext = self.persistentContainer.viewContext
        
        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatEntity")
        
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "userId = %@", userId)
        do {
            let result = try managedContext.fetch(fetchRequest)
            return result.first as? ChatEntity
        } catch {
            print("Failed")
            return nil
        }
    }
    
    @IBAction func cancel(_ sender: Any) {
        let error = NSError(domain: "com.kasim.firebasechat2.share", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error description"])
        extensionContext?.cancelRequest(withError: error)
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
        self.receiverData = self.users[indexPath.row].toJSON()
        if let chat = self.retrieveChat(userId: self.receiverData["id"] as? String ?? "" ){
            self.receiverData["roomId"] = chat.roomId ?? ""
        }
        self.performSegue(withIdentifier: "post", sender: nil)
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
    
    
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PostViewController {
            vc.receiverData = self.receiverData
        }
     }
     
    
}

extension UIView {
    
    
    func setRounded() {
        self.layer.cornerRadius = (self.frame.width / 2)
        self.layer.masksToBounds = true
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
