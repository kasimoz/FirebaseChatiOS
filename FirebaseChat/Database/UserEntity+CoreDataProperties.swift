//
//  UserEntity+CoreDataProperties.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 3.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//
//

import Foundation
import CoreData


extension UserEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var username: String?
    @NSManaged public var status: String?
    @NSManaged public var token: String?
    @NSManaged public var lastOnlineTime: Int64
    @NSManaged public var online: Bool
    @NSManaged public var phoneNumber: String?
    @NSManaged public var image: String?
    @NSManaged public var user: ChatEntity?

}


