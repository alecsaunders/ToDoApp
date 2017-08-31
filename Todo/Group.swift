//
//  Group.swift
//  Todo
//
//  Created by Alec Saunders on 8/31/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

struct Group {
    var groupName: String
    var parentGroupID: Int?
    var managedContextID: NSManagedObjectID
    
    init(groupName: String, parentGroupID: Int?, managedContextID: NSManagedObjectID) {
        self.groupName = groupName
        self.parentGroupID = parentGroupID
        self.managedContextID = managedContextID
    }
}
