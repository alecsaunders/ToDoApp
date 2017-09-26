//
//  ToDoModelAccessor.swift
//  Todo
//
//  Created by Alec Saunders on 8/25/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa


class ToDoModelAccessor {
    let appDelegate = NSApplication.shared.delegate as? AppDelegate
    var managedContext: NSManagedObjectContext? = nil
    
    init() {
        managedContext = appDelegate?.persistentContainer.viewContext
    }
    
    func getToDoItems() {
        
    }

    
    func managedContextDidSave(managedContext: NSManagedObjectContext) -> Bool {
        do {
            try managedContext.save()
            return true
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
            return false
        }
    }
}
