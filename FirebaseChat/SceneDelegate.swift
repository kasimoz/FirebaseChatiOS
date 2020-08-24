//
//  SceneDelegate.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 16.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import Firebase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let user = Auth.auth().currentUser{
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let vc = storyboard.instantiateViewController(withIdentifier: "logged")
            window?.rootViewController = vc
            window?.makeKeyAndVisible()
        }
        
        if let shortcutItem = connectionOptions.shortcutItem {
            if shortcutItem.type == "com.kasim.firebasechat2.newChat"{
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("shortcut"), object: nil, userInfo: nil)
                }
            }
        }
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        if shortcutItem.type == "com.kasim.firebasechat2.newChat"{
        }
    }
    

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        if let user = Auth.auth().currentUser{
            Database.database().reference().child("users").child(user.uid).child("online").setValue(true)
            Database.database().reference().child("users").child(user.uid).child("lastOnlineTime").setValue(ServerValue.timestamp())
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        if let user = Auth.auth().currentUser{
            Database.database().reference().child("users").child(user.uid).child("online").setValue(false)
            Database.database().reference().child("users").child(user.uid).child("lastOnlineTime").setValue(ServerValue.timestamp())
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        if let user = Auth.auth().currentUser{
            Database.database().reference().child("users").child(user.uid).child("online").setValue(false)
            Database.database().reference().child("users").child(user.uid).child("lastOnlineTime").setValue(ServerValue.timestamp())
        }
    }


}

