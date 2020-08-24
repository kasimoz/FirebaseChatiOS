//
//  AppDelegate.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 16.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UIKit
import Firebase
import CoreData
import Reachability

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let gcmMessageIDKey = "gcm.message_id"
    var reachability: Reachability?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in
                    
                    let replyAction = UNTextInputNotificationAction(
                        identifier: "reply.action",
                        title: "Reply on message",
                        textInputButtonTitle: "Send",
                        textInputPlaceholder: "type message")
                    
                    let pushNotificationButtons = UNNotificationCategory(
                        identifier: "allreply.action",
                        actions: [replyAction],
                        intentIdentifiers: [],
                        options: [])
                    
                    UNUserNotificationCenter.current().setNotificationCategories([pushNotificationButtons])
            })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // check internet connection
        reachability = try! Reachability()
        reachability?.stopNotifier()
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        do{
            try reachability?.startNotifier()
        }catch{
            print("could not start reachability notifier")
        }
        
        // create dynamic quick actions
        /*let icon = UIApplicationShortcutIcon(type: .compose)
         let item = UIApplicationShortcutItem(type: "com.kasim.firebasechat2.newChat", localizedTitle: "New Chat", localizedSubtitle: "", icon: icon, userInfo: nil)
         UIApplication.shared.shortcutItems = [item]*/
        
        return true
    }
    
    @objc func reachabilityChanged(note: Notification) {
        
        let reachability = note.object as! Reachability
        var dict : [String: AnyObject] = [:]
        switch reachability.connection {
        case .wifi:
            print("Reachable via WiFi")
            dict["reachable"] = true as AnyObject
        case .cellular:
            print("Reachable via Cellular")
            dict["reachable"] = true as AnyObject
        case .unavailable:
            print("Network not reachable")
            dict["reachable"] = false as AnyObject
        case .none:
            print("Network not reachable")
            dict["reachable"] = false as AnyObject
            
        }
        
        NotificationCenter.default.post(name: Notification.Name("reachable"), object: nil, userInfo: dict)
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    // [END receive_message]
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
    }
    
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = CustomPersistentContainer(name: "ChatDatabase")
        
        /*let description = NSPersistentStoreDescription()
         description.shouldMigrateStoreAutomatically = true
         description.shouldInferMappingModelAutomatically = true
         container.persistentStoreDescriptions =  [description]*/
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        
        let state = UIApplication.shared.applicationState
        if state == .background {
            completionHandler([[.alert, .badge, .sound]])
        }else if state == .active {
            if let vc = UIApplication.topViewController() {
                if vc is ChatsViewController{
                    completionHandler([])
                }else if vc is RoomViewController {
                    let roomId = (vc as! RoomViewController).roomUID
                    if roomId == userInfo["chatUID"] as? String {
                        completionHandler([])
                    }else{
                        completionHandler([[.alert, .badge, .sound]])
                    }
                }else{
                    completionHandler([[.alert, .badge, .sound]])
                }
            }else {
                completionHandler([[.alert, .badge, .sound]])
            }
        }
        
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        NotificationCenter.default.post(name: Notification.Name("notification"), object: nil, userInfo: userInfo)
        
        if  response.actionIdentifier  ==  "reply.action" {
            if let textResponse =  response as? UNTextInputNotificationResponse {
                let sendText =  textResponse.userText
                //NSLog("Received text message: \(sendText)")
                if let chatUID = userInfo["chatUID"], Auth.auth().currentUser?.uid != nil {
                    //NSLog("chat ID: \(chatUID)")
                    self.sendMessageToFirebase(message: sendText, lastMessage: sendText, chatUID: chatUID as! String, completion: { result in
                        completionHandler()
                    })
                }
            }
        }else{
            completionHandler()
        }
        // click action
    }
    
    func sendMessageToFirebase(message : String, lastMessage : String, chatUID : String, date : Int64 = Date().millisecondsSince1970, completion: @escaping (_ result: Bool)->()){
        
        let ref = Database.database().reference().child("chatMessages")
        let ref2 = Database.database().reference().child("chats")
        let message = [
            "sentBy": Auth.auth().currentUser!.uid,
            "message": message,
            "type": "text",
            "messageDate": date,
            "timestamp" : ServerValue.timestamp()] as [String : Any]
        let messageUID = ref.childByAutoId().key!
        ref.child(chatUID).child(messageUID).setValue(message)
        let lastMessageSend = [
            "sentBy": Auth.auth().currentUser!.uid,
            "message": lastMessage,
            "type": "text",
            "date": date,
            "timestamp" : ServerValue.timestamp()] as [String : Any]
        ref2.child(chatUID).child("message").setValue(lastMessageSend, withCompletionBlock: { error, ref in
            completion(true)
        })
    }
}
// [END ios_10_message_handling]

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    // [END refresh_token]
}


extension UIApplication {
    class func topViewController(_ viewController: UIViewController? = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController) -> UIViewController? {
        if let nav = viewController as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = viewController as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = viewController?.presentedViewController {
            return topViewController(presented)
        }
        return viewController
    }
}


