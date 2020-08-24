//
//  ChatUserMessage.swift
//  FirebaseChat
//
//  Created by KasimOzdemir on 16.06.2020.
//  Copyright © 2020 KasimOzdemir. All rights reserved.
//

import Foundation

struct ChatUserMessage {
    var chat : Chats?
    var user : User?
    var lastMessage : LastMessage?
    
    init(_ chat : Chats, user : User, lastMessage : LastMessage) {
        self.chat = chat
        self.user = user
        self.lastMessage = lastMessage
    }
}
