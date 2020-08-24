//
//  ShareContactViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 25.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

class ShareContactViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    
    
    @IBOutlet weak var tableView: UITableView!
    var contacts : [CNContact] = []
    var colors : [UIColor] = [Constants.contact1, Constants.contact2, Constants.contact3, Constants.contact4, Constants.contact5]
    var selectedIndex = -1
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contacts = self.getContactFromCNContact()
        self.tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationMessage(_:)), name: NSNotification.Name("notification"), object: nil)
        
    }
    
    @objc func notificationMessage(_ notification: NSNotification) {
        if let _ = notification.userInfo?["sender"] as? String {
            if let _ = notification.userInfo?["chatUID"] as? String {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func shareAction(_ sender: UIButton) {
        if self.selectedIndex != -1 {
            let contact = self.contacts[self.selectedIndex]
            let numbers: [String] = contact.phoneNumbers.map{ $0.value.stringValue }
            let name = "\(contact.givenName) \(contact.familyName)"
            let contactData : [String: Any] = [ "name" : name, "phoneNumber" : numbers.first ?? ""]
            NotificationCenter.default.post(name: Notification.Name("shareContact"), object: nil, userInfo: contactData)
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let letter = cell?.viewWithTag(1) as? UILabel
        let name = cell?.viewWithTag(2) as? UILabel
        let phoneNumber = cell?.viewWithTag(3) as? UILabel
        let contact = self.contacts[indexPath.row]
        let numbers: [String] = contact.phoneNumbers.map{ $0.value.stringValue }
        name?.text = "\(contact.givenName) \(contact.familyName)"
        phoneNumber?.text = numbers.first
        letter?.text = contact.givenName[0..<1]
        letter?.backgroundColor = self.colors[indexPath.row%5]
        return cell!
    }
    
    func getContactFromCNContact() -> [CNContact] {
        
        let contactStore = CNContactStore()
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactGivenNameKey,
            CNContactMiddleNameKey,
            CNContactFamilyNameKey,
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey
            ] as [Any]
        
        //Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
                
            } catch {
                print("Error fetching results for container")
            }
        }
        
        results.sort(by: { (first: CNContact, second: CNContact) -> Bool in
            first.givenName.localizedCompare(second.givenName) == .orderedAscending
        })
        
        return results
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: IndexPath.init(row: self.selectedIndex, section: 0))?.accessoryType = .none
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        self.selectedIndex = indexPath.row
        
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
    
}
