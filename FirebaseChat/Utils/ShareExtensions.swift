//
//  ShareExtensions.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 19.08.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import ObjectMapper
import CoreData


extension UIViewController {
    func convertToUserArray(items: [UserEntity]) -> [User]{
        var users : [User] = []
        for item in items {
            let user = Mapper<User>().map(JSONString: item.convertToDict().toJsonString())
            users.append(user!)
        }
        return users
    }
}

extension NSManagedObject {
    func convertToDict() -> [String: Any] {
        var dict: [String: Any] = [:]
        for attribute in self.entity.attributesByName {
            if let value = self.value(forKey: attribute.key) {
                dict[attribute.key] = value
            }
        }
        return dict
    }
}
