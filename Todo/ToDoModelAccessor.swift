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
    
    func populateMainTableToDoArray() -> [ToDo] {
        guard let managedObjects = fetchManagedObjectsFromCoreData(entityName: "ToDo") else { return [] }
        var toDoArray = managedObjects.map{mngObj in createToDoFromManagedObject(obj: mngObj)}
        toDoArray = toDoArray.sorted { $0.createdDate < $1.createdDate }
        return toDoArray
    }
    func populateSidebarGroupsArray() -> [Group] {
        guard let managedObjects = fetchManagedObjectsFromCoreData(entityName: "Group") else { return [] }
        var groupArray = managedObjects.map{mngObj in createGroupFromManagedObject(obj: mngObj)}
        return groupArray
    }
    
    func fetchManagedObjectsFromCoreData(entityName: String) -> [NSManagedObject]? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
        
        do {
            return try self.managedContext!.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        return nil
    }
    
    func createToDoFromManagedObject(obj: NSManagedObject) -> ToDo {
        let currentTitle = obj.value(forKey: "title") as? String ?? "Unnamed ToDo"
        let currentDate = obj.value(forKey: "createdDate") as? Date ?? Date()
        let currentCompleted = obj.value(forKey: "completed") as? Bool
        let currentNote = obj.value(forKey: "note") as? String
        let currentOrdinalPosition = obj.value(forKey: "ordinalPosition") as? Int
        let currentSidebarGroup = obj.value(forKey: "sidebarGroup") as? String
        let currentManagedContextID = obj.objectID
        
        let currentToDo = ToDo(title:           currentTitle,
                               createdDate:     currentDate,
                               completed:       currentCompleted,
                               note:            currentNote,
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
    
    func createNewGroup(groupName: String, parentGroupID: Int) -> Group? {
        guard let mc = managedContext else { return nil }
        let entity = NSEntityDescription.entity(forEntityName: "Group", in: mc)
        let groupRecord = NSManagedObject(entity: entity!, insertInto: mc)
        groupRecord.setValue(groupName, forKeyPath: "groupName")
        groupRecord.setValue(parentGroupID, forKeyPath: "parentGroupID")
        if managedContextDidSave(managedContext: mc) {
            let newGroup = createGroupFromManagedObject(obj: groupRecord)
            return newGroup
        }
        return nil
    }
    
    func createGroupFromManagedObject(obj: NSManagedObject) -> Group {
        let currentGroupName = obj.value(forKey: "groupName") as? String ?? "New Group"
        let currentParentGroupID = obj.value(forKey: "parentGroupID") as? Int
        let currentManagedContextID = obj.objectID
        
        let currentGroup = Group(groupName: currentGroupName, parentGroupID: currentParentGroupID, managedContextID: currentManagedContextID)
        return currentGroup
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
    
    func updatePosition(moID: NSManagedObjectID, newPosition: Int) {
        guard let mc = managedContext else { return }
        let changedManagedObject = mc.object(with: moID)
        changedManagedObject.setValue(newPosition, forKey: "ordinalPosition")
        if !managedContextDidSave(managedContext: mc) {
            print("failed to update ordinal position")
        }
    }
    
    func updateNote(newNote: String, moID: NSManagedObjectID) -> Bool {
        guard let mc = managedContext else { return false }
        let changedManagedObject = mc.object(with: moID)
        changedManagedObject.setValue(newNote, forKey: "note")
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
