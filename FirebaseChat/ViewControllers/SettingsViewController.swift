//
//  SettingsViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 16.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UITableViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var status: UITextField!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var phoneNumber: UILabel!
    @IBOutlet weak var profileImage: UIImageView!
    var saveButton : UIBarButtonItem!
    var usernameValue = ""
    var statusValue = ""
    var gesture : UITapGestureRecognizer!
    var dict : [String: AnyObject] = [:]
    var userRef : DatabaseReference!
    override func viewDidLoad() {
        super.viewDidLoad()
        let user = UserDefaults.standard.getUser()
        self.userInformation(username: user.username, phoneNumber: user.phoneNumber, status: user.status, image: user.image)
        self.userRef = Database.database().reference().child("users").child(Auth.auth().currentUser!.uid)
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            self.dict = snapshot.value as? [String : AnyObject] ?? [:]
            self.userInformation(username: self.dict["username"] as? String ?? "", phoneNumber: self.dict["phoneNumber"] as? String ?? "", status: self.dict["status"] as? String ?? "", image: self.dict["image"] as? String ?? "")
            self.indicator.stopAnimating()
        })
        self.saveButton = UIBarButtonItem.init(title: "Save", style: .plain, target: self, action: #selector(self.save(_:)))
        self.saveButton.tintColor = Constants.blue
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped(_ :)))
        self.profileImage.isUserInteractionEnabled = true
        self.profileImage.addGestureRecognizer(tapGestureRecognizer)
        NotificationCenter.default.addObserver(self, selector: #selector(self.notificationMessage(_:)), name: NSNotification.Name("notification"), object: nil)
        
    }
    
    @objc func notificationMessage(_ notification: NSNotification) {
        if let _ = notification.userInfo?["sender"] as? String {
            if let _ = notification.userInfo?["chatUID"] as? String {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func userInformation(username : String, phoneNumber : String, status : String, image : String){
        let ref = Storage.storage().reference(withPath: "images").child("thumb_\(image)")
        self.profileImage.sd_setImage(with: ref, placeholderImage: UIImage.init(systemName: "person.crop.circle.fill"))
        self.phoneNumber.text = phoneNumber
        self.username.text = username
        self.status.text = status
        self.statusValue = self.status.text ?? ""
        self.usernameValue = self.username.text ?? ""
        UserDefaults.standard.setUser(username: username, phoneNumber: phoneNumber, status: status, image: image)
    }
    
    @objc func profileImageTapped(_ tapGestureRecognizer: UITapGestureRecognizer)
    {
        if (dict["image"] as? String ?? "") == Constants.pImage{
            return
        }
        self.performSegue(withIdentifier: "image", sender: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        self.gesture = self.viewTouch()
    }
    
    
    
    @objc func keyboardWillHide(notification: NSNotification) {
        self.removeGesture(gesture: self.gesture)
    }
    
    @objc func save(_ sender : UIBarButtonItem){
        self.view.endEditing(true)
        self.userRef.child("username").setValue(self.username.text!, withCompletionBlock: { (error, reference) in
            if error == nil {
                self.usernameValue = self.username.text!
                UserDefaults.standard.setUser(username: self.usernameValue, status: self.statusValue)
            }
        })
        self.userRef.child("status").setValue(self.status.text!, withCompletionBlock: { (error, reference) in
            if error == nil {
                self.statusValue = self.status.text!
                UserDefaults.standard.setUser(username: self.usernameValue, status: self.statusValue)
            }
        })
        self.navigationItem.rightBarButtonItem = nil
    }
    
    
    @IBAction func signOut(_ sender: Any) {
        self.signOutAlert(completion: { result in
            if result {
                self.userRef.child("token").setValue("", withCompletionBlock: { (error, databaseReference) in
                    if error != nil {
                        return
                    }
                    do {
                        if (self.dict["image"] as? String ?? "") != Constants.pImage{
                            let thumbRef = Storage.storage().reference().child("images/thumb_\(self.dict["image"] as? String ?? "")")
                            let originalRef = Storage.storage().reference().child("images/\(self.dict["image"] as? String ?? "")")
                            thumbRef.delete(completion: nil)
                            originalRef.delete(completion: nil)
                            let documentsURL = URL.createFolder(folderName: "Photos")
                            let localURL = documentsURL!.appendingPathComponent(self.dict["image"] as? String ?? "")
                            URL.deleteFile(documentPath: localURL.path)
                        }
                        try Auth.auth().signOut()
                        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "login")
                        UIApplication.shared.windows.first?.rootViewController = vc
                    }
                    catch {
                        
                    }
                })
                
            }
        })
    }
    
    @IBAction func editAction(_ sender: Any) {
        self.alertProfileImage(completion: { result in
            switch result {
            case .Take:
                self.imagePicker(type: .camera)
                break
            case .Choose:
                self.imagePicker(type: .photoLibrary)
                break
            case .Delete:
                if (self.dict["image"] as? String ?? "") == Constants.pImage{
                    return
                }
                let thumbRef = Storage.storage().reference().child("images/thumb_\(self.dict["image"] as? String ?? "")")
                let originalRef = Storage.storage().reference().child("images/\(self.dict["image"] as? String ?? "")")
                thumbRef.delete(completion: nil)
                originalRef.delete(completion: nil)
                let documentsURL = URL.createFolder(folderName: "Photos")
                let localURL = documentsURL!.appendingPathComponent(self.dict["image"] as? String ?? "")
                URL.deleteFile(documentPath: localURL.path)
                self.userRef.child("image").setValue(Constants.pImage) { (error, databaseReference) in
                    if error == nil {
                        self.profileImage.image = UIImage.init(systemName: "person.crop.circle.fill")
                        self.dict["image"] = Constants.pImage as AnyObject
                        UserDefaults.standard.setUser(image: Constants.pImage)
                    }
                }
                break
            default:
                break
            }
        })
    }
    
    func imagePicker(type : UIImagePickerController.SourceType){
        let vc = UIImagePickerController()
        vc.sourceType = type
        vc.allowsEditing = true
        vc.mediaTypes = ["public.image"]
        vc.delegate = self
        self.present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[.editedImage] as? UIImage else {
            print("No image found")
            picker.dismiss(animated: true)
            return
        }
        picker.dismiss(animated: true, completion: {
            self.profileImage.image = image.thumbImage()
            let fileName = "\(UUID().uuidString).jpg"
            self.uploadFile(image: image, fileName: fileName)
        })
    }
    
    func uploadFile(image: UIImage, fileName : String) {
        self.indicator.startAnimating()
        let fileRef = Storage.storage().reference().child("images/\(fileName)")
        let fileThumbRef = Storage.storage().reference().child("images/thumb_\(fileName)")
        let file = image.jpegData(compressionQuality: 1.0)!
        let thumb = image.thumbImage().jpegData(compressionQuality: 1.0)!
        let metadataFile = StorageMetadata()
        metadataFile.contentType = "image/jpeg"
        let _ = fileThumbRef.putData(thumb, metadata: metadataFile) { (metadata, error) in
            guard let _ = metadata else {
                // Uh-oh, an error occurred!
                self.indicator.stopAnimating()
                return
            }
            let _ = fileRef.putData(file, metadata: metadataFile) { (metadata2, error) in
                self.indicator.stopAnimating()
                guard let _ = metadata2 else {
                    // Uh-oh, an error occurred!
                    return
                }
                self.userRef.child("image").setValue(fileName)
                self.dict["image"] = fileName as AnyObject
                UserDefaults.standard.setUser(image: fileName)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func usernameChanged(_ sender: UITextField) {
        if (!username.text!.isEmpty && username.text != self.usernameValue) || (!status.text!.isEmpty && status.text != self.statusValue) {
            self.navigationItem.rightBarButtonItem = self.saveButton
        }else{
            self.navigationItem.rightBarButtonItem = nil
        }
        
    }
    
    @IBAction func statusChanged(_ sender: UITextField) {
        if (!username.text!.isEmpty && username.text != self.usernameValue) || (!status.text!.isEmpty && status.text != self.statusValue) {
            self.navigationItem.rightBarButtonItem = self.saveButton
        }else{
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ImageViewController {
            vc.selectedImage = self.dict["image"] as? String
            vc.image = self.profileImage.image
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = Constants.grey_900
        header.textLabel?.font = UIFont.systemFont(ofSize: 14.0)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 4 {
            self.performSegue(withIdentifier: "media", sender: nil)
        }
    }
    
}


extension SettingsViewController: ZoomingViewController{
    func zoomingImageView(for transition: ZoomTransitioningDelegate) -> UIImageView? {
        return self.profileImage
    }
    
    func zoomingBackgroundView(for transition: ZoomTransitioningDelegate) -> UIView? {
        return nil
    }
    
    func zoomingType(for transition: ZoomTransitioningDelegate) -> Constants.SegueType? {
        return .imageVideo
    }
    
    
}
