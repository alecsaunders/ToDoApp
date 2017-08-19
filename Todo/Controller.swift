//
//  Controller.swift
//  Todo
//
//  Created by Alec Saunders on 8/19/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Foundation
import Cocoa
import CoreData

class MainController: NSObject {
    let appDelegate = NSApplication.shared().delegate as? AppDelegate
    var managedContext: NSManagedObjectContext? = nil
    var coreDataToDoManagedObjects: [NSManagedObject]? = nil
    var mainTableToDoArray: [ToDo] = []
    
    override init() {
        super.init()
        
        managedContext = self.appDelegate?.persistentContainer.viewContext
        coreDataToDoManagedObjects = fetchManagedObjectsFromCoreData(entityName: "ToDo")
        mainTableToDoArray = populateMainTableToDoArray()
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
    
    func populateMainTableToDoArray() -> [ToDo] {
        guard let managedObjects = self.coreDataToDoManagedObjects else { return [] }
        let tmpToDoArray = managedObjects.map{mngObj in createToDoFromManagedObject(obj: mngObj)}
        return tmpToDoArray.sorted{ $0.ordinalPosition < $1.ordinalPosition }
    }
    
    func createToDoFromManagedObject(obj: NSManagedObject) -> ToDo {
        let currentTitle = obj.value(forKey: "title") as? String ?? "Unnamed ToDo"
        let currentCompleted = obj.value(forKey: "completed") as? Bool
        let currentOrdinalPosition = obj.value(forKey: "ordinalPosition") as? Int
        let currentManagedContextID = obj.objectID
        
        let currentToDo = ToDo(title:           currentTitle,
                               completed:       currentCompleted,
                               ordinalPosition: currentOrdinalPosition,
                               managedContextID: currentManagedContextID)
        return currentToDo
    }
    
    func completedWasChecked(state: Int, btnIndex: Int) {
        print(state)
        print(btnIndex)
        switch state {
        case NSOnState:
            removeToDoEntityRecord(atIndex: btnIndex)
        case NSOffState:
            break
        default:
            break
        }
    }
    
    func removeToDoEntityRecord(atIndex: Int) {
        guard let context = self.managedContext else { return }
        guard let toDoMO = coreDataToDoManagedObjects else { return }
        context.delete(toDoMO[atIndex])
        do {
            try context.save()
            coreDataToDoManagedObjects!.remove(at: atIndex)
            mainTableToDoArray.remove(at: atIndex)
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
        }
    }
    
    func save(currentToDoTitle: String) {
        guard let mc = managedContext else { return }
        
        let entityName = "ToDo"
        
        let entity = NSEntityDescription.entity(forEntityName: entityName, in: mc)
        let toDoEntityRecord = NSManagedObject(entity: entity!, insertInto: mc)


        toDoEntityRecord.setValue(currentToDoTitle, forKeyPath: "title")
        toDoEntityRecord.setValue(false, forKeyPath: "completed")

        let ordinalPosition = mainTableToDoArray.count

        toDoEntityRecord.setValue(ordinalPosition, forKey: "ordinalPosition")

        do {
            try mc.save()
            coreDataToDoManagedObjects = fetchManagedObjectsFromCoreData(entityName: entityName)
            mainTableToDoArray.append(createToDoFromManagedObject(obj: toDoEntityRecord))
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func reorderToDos(dragOrigin: Int, dragDest: Int) {
        print("Drag Origin: \(dragOrigin)")
        print("Drag Dest: \(dragDest)")
        
        guard let mc = managedContext else { return }
        var alteredDragDest = dragDest
        if dragOrigin == dragDest - 1 { return }
        if dragOrigin < dragDest {
            alteredDragDest = dragDest - 1
        }
        
        let draggedItem = mainTableToDoArray[dragOrigin]
        mainTableToDoArray.remove(at: dragOrigin)
        mainTableToDoArray.insert(draggedItem, at: alteredDragDest)
        
        
        for i in 0..<mainTableToDoArray.count {
            mainTableToDoArray[i].ordinalPosition = i
            let mngdObj = mc.object(with: mainTableToDoArray[i].managedContextID)
            mngdObj.setValue(i, forKey: "ordinalPosition")
        }

        do {
            try mc.save()
            coreDataToDoManagedObjects = fetchManagedObjectsFromCoreData(entityName: "ToDo")
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}
