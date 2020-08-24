//
//  MessageEntity.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 18.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import ObjectMapper

struct Message: Mappable {
    var id: String = ""
    var roomId: String = ""
    var sentBy: String = ""
    var message: String = ""
    var type: String = ""
    var messageDate: Int64 = 0
    var timestamp: Int64 = 0
    
    init(id: String, roomId: String, sentBy: String, message: String, type: String, messageDate: Int64, timestamp: Int64) {
        self.id = id
        self.roomId = roomId
        self.sentBy = sentBy
        self.message = message
        self.type = type
        self.messageDate = messageDate
        self.timestamp = timestamp
    }
    
    init?(map: Map) {

    }

    mutating func mapping(map: Map) {
        id <- map["id"]
        roomId <- map["roomId"]
        sentBy <- map["sentBy"]
        message  <- map["message"]
        type  <- map["type"]
        messageDate  <- map["messageDate"]
        timestamp  <- map["timestamp"]
    }
}
