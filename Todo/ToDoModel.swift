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
    var completed: Bool
    var ordinalPosition: Int
    var managedContextID: NSManagedObjectID
    
    init(title: String, completed: Bool?, ordinalPosition: Int?, managedContextID: NSManagedObjectID) {
        self.title = title
        self.completed = completed ?? false
        self.ordinalPosition = ordinalPosition ?? 100
        self.managedContextID = managedContextID
    }
}
