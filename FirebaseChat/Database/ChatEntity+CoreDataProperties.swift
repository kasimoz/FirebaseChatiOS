//
//  ChatEntity+CoreDataProperties.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 3.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//
//

import Foundation
import CoreData


extension ChatEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatEntity> {
        return NSFetchRequest<ChatEntity>(entityName: "ChatEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var userId: String?
    @NSManaged public var roomId: String?
    @NSManaged public var count: Int16
    @NSManaged public var room: LastMessageEntity?
    @NSManaged public var user: UserEntity?

}
