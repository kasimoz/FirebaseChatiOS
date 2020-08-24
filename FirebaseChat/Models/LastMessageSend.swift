//
//  LastMessageSend.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 19.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import FirebaseDatabase

struct LastMessageSend {
    var sentBy: String = ""
    var message: String = ""
    var type: String = ""
    var date: Int64 = 0
    var timestamp: [AnyHashable: Any]!
    
    init(sentBy: String, message: String, type: String, date: Int64 = Date().millisecondsSince1970, timestamp: [AnyHashable: Any] = ServerValue.timestamp()) {
        self.sentBy = sentBy
        self.message = message
        self.type = type
        self.date = date
        self.timestamp = timestamp
    }
    

}
