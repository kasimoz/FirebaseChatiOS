//
//  Constants.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 19.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import UIKit

class Constants {
    
    enum CellType : String {
        case TextSender = "textSender", TextReceiver = "textReceiver",
        ContactSender = "contactSender", ContactReceiver =  "contactReceiver",
        ImageSender =  "imageSender", ImageReceiver =  "imageReceiver",
        VideoSender =  "videoSender", VideoReceiver =  "videoReceiver",
        LocationSender =  "locationSender", LocationReceiver =  "locationReceiver",
        RecordSender =  "recordSender", RecordReceiver =  "recordReceiver",
        ReplySender =  "replySender", ReplyReceiver =  "replyReceiver",
        Unread =  "unread"
    }
    
    enum AttachmentType {
        case Photo, Video, Gallery, Location, Contact, Cancel
    }
    
    enum PhotoEditType {
        case Take, Choose, Delete, Cancel
    }
    
    enum SegueType {
        case imageVideo, profile, none
    }
    
    enum CaptureMode {
        case photo, video, none
    }
    
    static var  blue = UIColor.init(hexString: "051E34")
    static var  orange = UIColor.init(hexString: "F6820A")
    
    static var  colorSender = UIColor.init(hexString: "262D33")
    static var  colorSender2 = UIColor.init(hexString: "94A7B7")
    static var  colorBorder = UIColor.init(hexString: "9EC2E2")
    static var  colorReceiver = UIColor.init(hexString: "F3B675")
    static var  colorReceiver2 = UIColor.init(hexString: "E8CFB4")
    
    static var  grey_100 = UIColor.init(hexString: "F5F5F5")
    static var  grey_300 = UIColor.init(hexString: "E0E0E0")
    static var  grey_500 = UIColor.init(hexString: "9E9E9E")
    static var  grey_700 = UIColor.init(hexString: "808080")
    static var  grey_900 = UIColor.init(hexString: "5A5A5A")
    
    static var  contact1 = UIColor.init(hexString: "673AB7")
    static var  contact2 = UIColor.init(hexString: "FFC107")
    static var  contact3 = UIColor.init(hexString: "03A9F4")
    static var  contact4 = UIColor.init(hexString: "F44336")
    static var  contact5 = UIColor.init(hexString: "009688")
    
    static var  pImage = "profile_image.png"
    static var  status = "Firebase Chat App"
}


