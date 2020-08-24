//
//  LoginViewController.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 16.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController,UITextFieldDelegate {
    @IBOutlet weak var detail: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var verifyButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var verificationCode: UITextField!
    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var formViewBottom: NSLayoutConstraint!
    var verificationID = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        // Do any additional setup after loading the view.
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        // Get required info out of the notification
        if  let userInfo = notification.userInfo, let endValue = userInfo[UIResponder.keyboardFrameEndUserInfoKey], let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey], let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] {
            let keyboardRectangle = (endValue as AnyObject).cgRectValue
            let keyboardHeight = keyboardRectangle!.height
            formViewBottom.constant = keyboardHeight
            
            let duration = (durationValue as AnyObject).doubleValue
            let options = UIView.AnimationOptions(rawValue: UInt((curveValue as AnyObject).integerValue << 16))
            UIView.animate(withDuration: duration!, delay: 0, options: options, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if  let userInfo = notification.userInfo, let durationValue = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey], let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] {
            
            formViewBottom.constant = 0
            
            let duration = (durationValue as AnyObject).doubleValue
            let options = UIView.AnimationOptions(rawValue: UInt((curveValue as AnyObject).integerValue << 16))
            UIView.animate(withDuration: duration!, delay: 0, options: options, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func start(_ sender: Any) {
        if self.username.text!.isEmpty || self.phoneNumber.text!.isEmpty{
            return
        }
        
        PhoneAuthProvider.provider().verifyPhoneNumber(self.phoneNumber.text!, uiDelegate:nil) {
            verificationID, error in
            if ((error) != nil) {
                // Handles error
                print(error?.localizedDescription)
                self.detail.text = "Phone number failed"
                return
            }
            self.verificationID = verificationID ?? ""
            self.enableViews(self.verificationCode,self.verifyButton, self.resendButton)
            self.disableViews(self.startButton, self.username, self.phoneNumber)
            self.detail.text = "Code Sent"
            self.verificationCode.becomeFirstResponder()
            
        }
        
    }
    
    @IBAction func verify(_ sender: Any) {
        if self.verificationCode.text!.isEmpty{
            return
        }
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: self.verificationID,
                                                                 verificationCode: self.verificationCode.text!)
        Auth.auth().signInAndRetrieveData(with: credential) { authData, error in
            if ((error) != nil) {
                // Handles error
                print(error?.localizedDescription)
                self.detail.text = "Verification failed"
                return
            }
            self.disableViews(self.startButton, self.verifyButton, self.resendButton)
            self.detail.text = "Verification succeeded"
            let userID = Auth.auth().currentUser!.uid
            Database.database().reference().child("users").child(userID).child("image").observeSingleEvent(of: .value, with: { dataSnapshot in
                let image  = (dataSnapshot.value as? String) ?? Constants.pImage
                let user : [AnyHashable: Any] = [
                    "username" : self.username.text!,
                    "phoneNumber" : self.phoneNumber.text!,
                    "online" : true,
                    "token" : "",
                    "status" : Constants.status,
                    "lastOnlineTime" : ServerValue.timestamp(),
                    "image" : image
                ]
                Database.database().reference().child("users").child(userID).setValue(user, withCompletionBlock: { (error, databaseReference) in
                    if error == nil {
                        UserDefaults.standard.setUser(username: self.username.text!, phoneNumber: self.phoneNumber.text!, status: Constants.status, image: image)
                        self.performSegue(withIdentifier: "logged", sender: nil)
                    }
                })
                
            })
            
            
        }
    }
    
    @IBAction func resend(_ sender: Any) {
        PhoneAuthProvider.provider().verifyPhoneNumber(self.phoneNumber.text!, uiDelegate:nil) {
            verificationID, error in
            if ((error) != nil) {
                // Handles error
                print(error?.localizedDescription)
                self.detail.text = "Phone number failed"
                return
            }
            self.verificationID = verificationID ?? ""
            self.enableViews(self.verificationCode,self.verifyButton, self.resendButton)
            self.disableViews(self.startButton, self.username, self.phoneNumber)
            self.detail.text = "Code Sent Again"
            self.verificationCode.becomeFirstResponder()
        }
    }
    
    func enableViews(_ views: UIView...) {
        for v in views {
            if v is UIButton {
                (v as! UIButton).isEnabled = true
            }else if v is UITextField{
                (v as! UITextField).isEnabled = true
            }
        }
    }
    
    func disableViews(_ views: UIView...) {
        for v in views {
            if v is UIButton {
                (v as! UIButton).isEnabled = true
            }else if v is UITextField{
                (v as! UITextField).isEnabled = true
            }
        }
    }
}
