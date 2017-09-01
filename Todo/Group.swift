//
//  Group.swift
//  Todo
//
//  Created by Alec Saunders on 8/31/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

struct Department {
    let name:String
    var accounts: [Group] = []
    
    init (name:String){
        self.name = name
    }
}

struct MainCategory {
    var groupName: String
}

struct Group {
    var groupName: String
    var groupID: NSManagedObjectID?
    var system: Bool = false
    
    init(groupName: String) {
        self.groupName = groupName
    }
    
    init(groupName: String, groupID: NSManagedObjectID) {
        self.groupName = groupName
        self.groupID = groupID
    }
}
