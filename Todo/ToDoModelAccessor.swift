//
//  ToDoModelAccessor.swift
//  Todo
//
//  Created by Alec Saunders on 8/25/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa


class ToDoModelAccessor {
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    var managedObjectContext: NSManagedObjectContext
    
    init() {
        managedObjectContext = appDelegate.persistentContainer.viewContext
    }
    
    func getToDoItems() {
        
    }

    
    func managedContextDidSave() -> Bool {
        do {
            try managedObjectContext.save()
            return true
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
            return false
        }
    }
}
