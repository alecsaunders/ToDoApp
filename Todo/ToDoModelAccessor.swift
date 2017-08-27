//
//  ToDoModelAccessor.swift
//  Todo
//
//  Created by Alec Saunders on 8/25/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa


class ToDoModelAccessor {
    let appDelegate = NSApplication.shared().delegate as? AppDelegate
    var managedContext: NSManagedObjectContext? = nil
    
    init() {
        managedContext = appDelegate?.persistentContainer.viewContext
    }
    
    func createToDoFromManagedObject(obj: NSManagedObject) -> ToDo {
        let currentTitle = obj.value(forKey: "title") as? String ?? "Unnamed ToDo"
        let currentCompleted = obj.value(forKey: "completed") as? Bool
        let currentOrdinalPosition = obj.value(forKey: "ordinalPosition") as? Int
        let currentSidebarGroup = obj.value(forKey: "sidebarGroup") as? String
        let currentManagedContextID = obj.objectID
        
        let currentToDo = ToDo(title:           currentTitle,
                               completed:       currentCompleted,
                               ordinalPosition: currentOrdinalPosition,
                               sidebarGroup:    currentSidebarGroup,
                               managedContextID: currentManagedContextID)
        return currentToDo
    }
    
    func createNewToDo(title: String, ordinalPosition: Int) -> ToDo? {
        guard let mc = managedContext else { return nil }
        let entity = NSEntityDescription.entity(forEntityName: "ToDo", in: mc)
        let toDoEntityRecord = NSManagedObject(entity: entity!, insertInto: mc)
        toDoEntityRecord.setValue(title, forKeyPath: "title")
        toDoEntityRecord.setValue(false, forKeyPath: "completed")
        if managedContextDidSave(managedContext: mc) {
            let newToDo = createToDoFromManagedObject(obj: toDoEntityRecord)
            return newToDo
        }
        return nil
    }
    
    func updateSidebarGroup(moID: NSManagedObjectID, newGroup: String) -> Bool {
        guard let mc = managedContext else { return false }
        let changedManagedObject = mc.object(with: moID)
        changedManagedObject.setValue(newGroup, forKey: "sidebarGroup")
        if managedContextDidSave(managedContext: mc) {
            return true
        }
        return false
    }
    
    func updateTitle(moID: NSManagedObjectID, newTitle: String) -> Bool {
        guard let mc = managedContext else { return false }
        let changedManagedObject = mc.object(with: moID)
        changedManagedObject.setValue(newTitle, forKey: "title")
        if managedContextDidSave(managedContext: mc) {
            return true
        }
        return false
    }
    
    func deleteManagedObject(moID: NSManagedObjectID) -> Bool {
        guard let mc = managedContext else { return false }
        mc.delete(mc.object(with: moID))
        if managedContextDidSave(managedContext: mc) {
            return true
        }
        return false
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
