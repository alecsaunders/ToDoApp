//
//  ToDoModel.swift
//  Todo
//
//  Created by Alec Saunders on 8/19/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Foundation
import CoreData

struct ToDo {
    var title: String
    var createdDate: Date
    var completed: Bool
    var ordinalPosition: Int
    var sidebarGroup: String
    var managedContextID: NSManagedObjectID
    
    init(title: String, createdDate: Date?, completed: Bool?, ordinalPosition: Int?, sidebarGroup: String?, managedContextID: NSManagedObjectID) {
        self.title = title
        self.createdDate = createdDate ?? Date()
        self.completed = completed ?? false
        self.ordinalPosition = ordinalPosition ?? 100
        self.sidebarGroup = sidebarGroup ?? "All"
        self.managedContextID = managedContextID
    }
}
