//
//  DBHelper.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 2.07.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import ObjectMapper

extension UIViewController {
    
    // <--------------LastMessage--------------->
    
    func createLastMessage(lastMessage : LastMessage){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let lastMessageEntity = NSEntityDescription.entity(forEntityName: "LastMessageEntity", in: managedContext)!
        
        
        let messageObject = NSManagedObject(entity: lastMessageEntity, insertInto: managedContext)
        messageObject.setValuesForKeys(lastMessage.toJSON())
        
        do {
            try managedContext.save()
            
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func retrieveLastMessage(id : String) -> LastMessageEntity? {
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LastMessageEntity")
        
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        do {
            let result = try managedContext.fetch(fetchRequest)
            return result.first as? LastMessageEntity
        } catch {
            print("Failed")
            return nil
        }
    }
    
    func updateLastMessage(lastMessage : LastMessage){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "LastMessageEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %@", lastMessage.id)
        do
        {
            let items = try managedContext.fetch(fetchRequest)
            
            let objectUpdate = items[0] as! NSManagedObject
            objectUpdate.setValuesForKeys(lastMessage.toJSON())
            do{
                try managedContext.save()
            }
            catch
            {
                print(error)
            }
        }
        catch
        {
            print(error)
        }
    }
    
    func updateLastMessage(id : String, message : String = "", type : String = "text"){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "LastMessageEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        do
        {
            let items = try managedContext.fetch(fetchRequest)
            
            let objectUpdate = items[0] as! NSManagedObject
            objectUpdate.setValue(message, forKey: "message")
            objectUpdate.setValue(type, forKey: "type")
            do{
                try managedContext.save()
            }
            catch
            {
                print(error)
            }
        }
        catch
        {
            print(error)
        }
    }
    
    func deleteLastMessage(message : LastMessage){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "LastMessageEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %@", message.id)
        do
        {
            if let result = try? managedContext.fetch(fetchRequest){
                for object in result {
                    managedContext.delete(object as! NSManagedObject)
                }
            }
        }
        catch
        {
            print(error)
        }
    }
    
    func insertOrUpdateLastMessage(lastMessage : LastMessage){
        if self.checkIfItemExist(id: lastMessage.id, entityName: "LastMessageEntity") {
            updateLastMessage(lastMessage: lastMessage)
        }else{
            createLastMessage(lastMessage: lastMessage)
        }
    }
    
    // <--------------Check If Item Exist--------------->
    
    func checkIfItemExist(id: String, entityName : String) -> Bool {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return false}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        fetchRequest.fetchLimit =  1
        fetchRequest.predicate = NSPredicate(format: "id == %@" ,id)
        
        do {
            let count = try managedContext.count(for: fetchRequest)
            if count > 0 {
                return true
            }else {
                return false
            }
        }catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
            return false
        }
    }
    
    // <--------------User--------------->
    
    func createUser(user : User){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let userEntity = NSEntityDescription.entity(forEntityName: "UserEntity", in: managedContext)!
        
        
        let userObject = NSManagedObject(entity: userEntity, insertInto: managedContext)
        userObject.setValuesForKeys(user.toJSON())
        
        do {
            try managedContext.save()
            
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func updateUser(user : User){
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "UserEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %@", user.id)
        do
        {
            let items = try managedContext.fetch(fetchRequest)
            
            let objectUpdate = items[0] as! NSManagedObject
            objectUpdate.setValuesForKeys(user.toJSON())
            do{
                try managedContext.save()
            }
            catch
            {
                print(error)
            }
        }
        catch
        {
            print(error)
        }
    }
    
    func retrieveUsers() -> [UserEntity]? {
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "UserEntity")
    
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "username", ascending: true)]
        
        do {
            let result = try managedContext.fetch(fetchRequest)
            return result as? [UserEntity]
        } catch {
            print("Failed")
            return []
        }
    }
    
    func deleteUser(user : User){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "UserEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %@", user.id)
        do
        {
            if let result = try? managedContext.fetch(fetchRequest).first{
                managedContext.delete(result as! NSManagedObject)
            }
        }
        catch
        {
            print(error)
        }
    }
    
    func insertOrUpdateUser(user : User){
        if self.checkIfItemExist(id: user.id, entityName: "UserEntity") {
            updateUser(user: user)
        }else{
            createUser(user: user)
        }
    }
    
    // <--------------Chat--------------->
    
    func createChat(chats : Chats, user : User ,lastMessage : LastMessage){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let userObject = UserEntity.init(context: managedContext)
        userObject.setValuesForKeys(user.toJSON())
        
        let lastMessageObject = LastMessageEntity.init(context: managedContext)
        lastMessageObject.setValuesForKeys(lastMessage.toJSON())
        
        //let chatEntity = NSEntityDescription.entity(forEntityName: "ChatEntity", in: managedContext)!
        
        let chatObject = ChatEntity.init(context: managedContext)
        chatObject.id = UUID.init(uuidString: chats.id)
        chatObject.roomId = chats.roomId
        chatObject.userId = chats.userId
        chatObject.count = Int16(chats.count)
        chatObject.user = userObject
        chatObject.room = lastMessageObject
        //chatObject.setValuesForKeys(chats.toJSON())
        do {
            try managedContext.save()
            
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func updateCount(roomId : String, count: Int){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "ChatEntity")
        fetchRequest.predicate = NSPredicate(format: "roomId = %@", roomId)
        do
        {
            let items = try managedContext.fetch(fetchRequest)
            
            let objectUpdate = items[0] as! NSManagedObject
            objectUpdate.setValue(Int16(count), forKey: "count")
            do{
                try managedContext.save()
            }
            catch
            {
                print(error)
            }
        }
        catch
        {
            print(error)
        }
    }
    
    func retrieveChats() -> [ChatEntity]? {
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatEntity")
        
        //        fetchRequest.fetchLimit = 1
        //fetchRequest.predicate = NSPredicate(format: "id = %@", roomId)
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "room.timestamp", ascending: false)]
        //
        do {
            let result = try managedContext.fetch(fetchRequest)
            return result as? [ChatEntity]
        } catch {
            print("Failed")
            return []
        }
    }
    
    func retrieveChat(userId : String) -> ChatEntity? {
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatEntity")
        
        fetchRequest.fetchLimit = 1
        fetchRequest.predicate = NSPredicate(format: "userId = %@", userId)
        do {
            let result = try managedContext.fetch(fetchRequest)
            return result.first as? ChatEntity
        } catch {
            print("Failed")
            return nil
        }
    }
    
    func deleteChat(chat : Chats){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "ChatEntity")
        let predicate1 = NSPredicate(format: "roomId = %@", chat.roomId)
        let predicate2  = NSPredicate(format: "userId = %@", chat.userId)
        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [predicate1, predicate2])
        fetchRequest.predicate = andPredicate
        do
        {
            if let result = try? managedContext.fetch(fetchRequest){
                for object in result {
                    managedContext.delete(object as! NSManagedObject)
                }
            }
        }
        catch
        {
            print(error)
        }
    }
    
    // <--------------Reset All Core Data--------------->
    
    
    func resetAllCoreData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        // get all entities and loop over them
        let entityNames = appDelegate.persistentContainer.managedObjectModel.entities.map({ $0.name!})
        entityNames.forEach { [weak self] entityName in
            let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
            
            do {
                try managedContext.execute(deleteRequest)
                try managedContext.save()
            } catch {
                // error
            }
        }
    }
    
    // <--------------Message--------------->
    
    func createMessage(message : Message){
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let lastMessageEntity = NSEntityDescription.entity(forEntityName: "MessageEntity", in: managedContext)!
        
        
        let messageObject = NSManagedObject(entity: lastMessageEntity, insertInto: managedContext)
        messageObject.setValuesForKeys(message.toJSON())
        
        do {
            try managedContext.save()
            
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func updateMessage(message : Message){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "MessageEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %@", message.id)
        do
        {
            let items = try managedContext.fetch(fetchRequest)
            
            let objectUpdate = items[0] as! NSManagedObject
            objectUpdate.setValuesForKeys(message.toJSON())
            do{
                try managedContext.save()
            }
            catch
            {
                print(error)
            }
        }
        catch
        {
            print(error)
        }
    }
    
    func deleteMessage(message : Message){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "MessageEntity")
        fetchRequest.predicate = NSPredicate(format: "id = %@", message.id)
        do
        {
            if let result = try? managedContext.fetch(fetchRequest){
                for object in result {
                    managedContext.delete(object as! NSManagedObject)
                }
            }
        }
        catch
        {
            print(error)
        }
    }
    
    func deleteRoom(id : String){
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest:NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "MessageEntity")
        fetchRequest.predicate = NSPredicate(format: "roomId = %@", id)
        do
        {
            if let result = try? managedContext.fetch(fetchRequest){
                for object in result {
                    managedContext.delete(object as! NSManagedObject)
                }
            }
        }
        catch
        {
            print(error)
        }
    }
    
    func insertOrUpdateMessage(message : Message){
        if self.checkIfItemExist(id: message.id, entityName: "MessageEntity") {
            updateMessage(message: message)
        }else{
            createMessage(message: message)
        }
    }
    
    func retrieveMessages(roomId: String, timestamp: Int64) -> [MessageEntity]? {
        
        //As we know that container is set up in the AppDelegates so we need to refer that container.
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        
        //We need to create a context from this container
        let managedContext = appDelegate.persistentContainer.viewContext
        
        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "MessageEntity")
        
        fetchRequest.fetchLimit = 20
        let predicate1 = NSPredicate(format: "roomId = %@", roomId)
        let predicate2  = NSPredicate(format: "timestamp < %lld", timestamp)
        let andPredicate = NSCompoundPredicate(type: .and, subpredicates: [predicate1, predicate2])
        fetchRequest.predicate = andPredicate
        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "timestamp", ascending: false)]
        //
        do {
            let result = try managedContext.fetch(fetchRequest)
            return result as? [MessageEntity]
        } catch {
            print("Failed")
            return []
        }
    }
    
    
    // <--------------Converters--------------->
    
    func convertToChatUserMessageArray(items: [ChatEntity]) -> [ChatUserMessage]{
        var chats : [ChatUserMessage] = []
        for item in items {
            var chatDict = item.convertToDict()
            let id = chatDict["id"] as? UUID
            chatDict["id"] = id?.uuidString
            let chat = Mapper<Chats>().map(JSONString: chatDict.toJsonString())
            let user = Mapper<User>().map(JSONString: item.user!.convertToDict().toJsonString())
            let message = Mapper<LastMessage>().map(JSONString: item.room!.convertToDict().toJsonString())
            let newItem = ChatUserMessage.init(chat!, user: user!, lastMessage: message!)
            chats.append(newItem)
        }
        return chats
    }
    
    func convertToMessageArray(items: [MessageEntity]) -> [Message]{
        var messages : [Message] = []
        for item in items {
            let message = Mapper<Message>().map(JSONString: item.convertToDict().toJsonString())
            messages.append(message!)
        }
        return messages
    }
}
