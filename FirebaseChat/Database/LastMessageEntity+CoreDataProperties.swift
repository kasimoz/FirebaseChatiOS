//
//  LastMessageEntity+CoreDataProperties.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 3.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//
//

import Foundation
import CoreData


extension LastMessageEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LastMessageEntity> {
        return NSFetchRequest<LastMessageEntity>(entityName: "LastMessageEntity")
    }

    @NSManaged public var id: String?
    @NSManaged public var sentBy: String?
    @NSManaged public var message: String?
    @NSManaged public var timestamp: Int64
    @NSManaged public var date: Int64
    @NSManaged public var type: String?
    @NSManaged public var roomId: ChatEntity?

}
