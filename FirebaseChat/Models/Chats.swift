//
//  ChatsEntity.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 16.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import ObjectMapper

struct Chats: Mappable {
    var id: String = ""
    var roomId: String = ""
    var userId: String = ""
    var count: Int = 0
    
    init(id : String, roomId: String, userId: String, count: Int) {
        self.id = id
        self.roomId = roomId
        self.userId = userId
        self.count = count
    }
    
    init?(map: Map) {

    }

    mutating func mapping(map: Map) {
        id <- map["id"]
        roomId <- map["roomId"]
        userId  <- map["userId"]
        count  <- map["count"]
    }
}

