//
//  UserEntity.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 16.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import ObjectMapper

struct User: Mappable {
    var id: String = ""
    var username: String = ""
    var token: String = ""
    var status: String = ""
    var lastOnlineTime: Int64 = 0
    var online: Bool = false
    var phoneNumber: String = ""
    var image: String = ""
    
    init(username : String, phoneNumber : String, status : String, image : String) {
        self.username = username
        self.phoneNumber  = phoneNumber
        self.status = status
        self.image = image
    }
    
    init?(map: Map) {

    }

    mutating func mapping(map: Map) {
        id <- map["id"]
        username <- map["username"]
        token  <- map["token"]
        status  <- map["status"]
        lastOnlineTime  <- map["lastOnlineTime"]
        online  <- map["online"]
        phoneNumber  <- map["phoneNumber"]
        image  <- map["image"]
    }
}
