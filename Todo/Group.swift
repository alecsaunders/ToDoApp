//
//  Group.swift
//  Todo
//
//  Created by Alec Saunders on 8/31/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

enum GroupType: Int {
    case system
    case custom
}

struct Group {
    var groupName: String
    var parentGroupID: Int?
    var type: GroupType
    var managedContextID: NSManagedObjectID?
    
    init(groupName: String, parentGroupID: Int?, groupType: GroupType, managedContextID: NSManagedObjectID?) {
        self.groupName = groupName
        self.parentGroupID = parentGroupID
        self.type = groupType
        self.managedContextID = managedContextID
    }
}
