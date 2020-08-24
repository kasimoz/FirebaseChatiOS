//
//  NotificationService.swift
//  notification
//
//  Created by KasimOzdemir on 9.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import UserNotifications
import FirebaseUI
import Firebase
import FirebaseAuth

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        if let bestAttemptContent = bestAttemptContent {
            let type = bestAttemptContent.userInfo["type"] as! String
            bestAttemptContent.title = "\(bestAttemptContent.userInfo["title"] as! String)"
            bestAttemptContent.body = "\((bestAttemptContent.userInfo["body"] as! String).messageBody(type : type))"
            if type == "image" || type == "video" {
               let urlString = bestAttemptContent.userInfo["imageUrl"] as! String
                if let url = URL.init(string:urlString) {
                    let attachmentStorage = AttachmentStorage()
                    attachmentStorage.store(url: url, filename: bestAttemptContent.userInfo["body"] as! String) { (path, error) in
                        if let path = path {
                            do {
                                let attachment = try UNNotificationAttachment(identifier: "image", url: path, options: nil)
                                bestAttemptContent.attachments = [attachment]
                                contentHandler(bestAttemptContent)
                                return
                            } catch {
                                contentHandler(bestAttemptContent)
                                return
                            }
                        }
                    }
                }else{
                    contentHandler(bestAttemptContent)

                }
            }else{
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}


class AttachmentStorage {

    func store(url: URL, filename: String, completion: ((URL?, Error?) -> ())?) {
        // obtain path to temporary file
        //let filename = ProcessInfo.processInfo.globallyUniqueString

        let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(filename)")

        // fetch attachment
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            let _ = try! data?.write(to: path)
            completion?(path, error)
        }
        task.resume()
    }

}

extension String {
    func messageBody(type : String) -> String {
        switch type {
        case "text":
            return self
        case "image":
            return "📷 Photo"
        case "video":
            return "🎥 Video"
        case "contact":
            return "👤 \(self.split(separator: "|").map(String.init).first!)"
        case "record":
            let first = self.split(separator: "|").map(String.init).first!
            let time = "🎙️ \(String(describing: Int(first)?.getTime() ?? "00:00"))"
            return time
        case "location":
            return "📍 Location"
        case "reply":
            return self.split(separator: "|").map(String.init).last!
        default:
            return ""
        }
    }
}

extension Int {
    func getTime() -> String {
        let sec = (self) % 60
        let min = ((self) / (60)) % 60
        return String.init(format: "%02d:%02d", min, sec)
    }
}
