//
//  CustomPersistentContainer.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 11.08.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import CoreData

class CustomPersistentContainer: NSPersistentContainer {
    
    override open class func defaultDirectoryURL() -> URL {
        var storeURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.firebaseChat.share")
        storeURL = storeURL?.appendingPathComponent("ChatDatabase.sqlite")
        return storeURL!
    }
    
}



