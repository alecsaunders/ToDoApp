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
    var note: String
    var ordinalPosition: Int
    var managedContextID: NSManagedObjectID
    
    init(title: String, createdDate: Date?, completed: Bool?, note: String?, ordinalPosition: Int?, managedContextID: NSManagedObjectID) {
        self.title = title
        self.createdDate = createdDate ?? Date()
        self.completed = completed ?? false
        self.note = note ?? ""
        self.ordinalPosition = ordinalPosition ?? 100
        self.managedContextID = managedContextID
    }
}
