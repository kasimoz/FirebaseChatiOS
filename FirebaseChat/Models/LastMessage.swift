//
//  LastMessageEntity.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 16.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import ObjectMapper

struct LastMessage: Mappable {
    var id: String = ""
    var sentBy: String = ""
    var message: String = ""
    var type: String = ""
    var date: Int64 = 0
    var timestamp: Int64 = 0
    
    init(id: String, sentBy: String, message: String, type: String, date: Int64, timestamp: Int64) {
        self.id = id
        self.sentBy = sentBy
        self.message = message
        self.type = type
        self.date = date
        self.timestamp = timestamp
    }
    
    init?(map: Map) {

    }

    mutating func mapping(map: Map) {
        id <- map["id"]
        sentBy <- map["sentBy"]
        message  <- map["message"]
        type  <- map["type"]
        date  <- map["date"]
        timestamp  <- map["timestamp"]
    }
}
