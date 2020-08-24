//
//  MessageEntity+CoreDataProperties.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 3.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//
//

import Foundation
import CoreData


extension MessageEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageEntity> {
        return NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var roomId: String?
    @NSManaged public var sentBy: String?
    @NSManaged public var type: String?
    @NSManaged public var timestamp: Int64
    @NSManaged public var messageDate: Int64
    @NSManaged public var message: String?

}
