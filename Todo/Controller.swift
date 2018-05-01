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

protocol MainControllerDelegate {
    func assigneToDoToGroup(moID: NSManagedObjectID, group: Group)
}

class MainController: NSObject, NSFetchedResultsControllerDelegate, InfoControllerDelegate, TableViewMenuDelegate, MTVDel2, MainControllerDelegate {
    let dataController = DataController()
    let toDoModelAcessor = ToDoModelAccessor()
    var toDoFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    weak var mainTableViewDelgate: MainTableViewDelgate?
    var categoryDelegate: CategoryDelegate?
    var fetchedToDos: [ToDo]?
    
    override init() {
        super.init()
        
        initializeToDoFetchedResultsController()
    }
    
    func initializeToDoFetchedResultsController() {
        let moc = dataController.managedObjectContext
        
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ToDo")
        let userDefaults = NSUserDefaultsController().defaults
        if let retentionValue = userDefaults.value(forKey: "completeRetention") as? Int {
            let retentionDelta = Calendar.current.date(byAdding: .day, value: retentionValue * -1, to: Date())! as NSDate
            fetch.predicate = NSPredicate(format: "completedDate < %@", retentionDelta)
        } else {
            let retentionDelta = Calendar.current.date(byAdding: .day, value: -30, to: Date())! as NSDate
            fetch.predicate = NSPredicate(format: "completedDate < %@", retentionDelta)
        }
        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            try moc.execute(batchDelete)
        } catch {
            fatalError("Failed to execute request: \(error)")
        }
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ToDo")
        let sort = NSSortDescriptor(key: "createdDate", ascending: true)
        request.sortDescriptors = [sort]
        
        if let predicate = categoryDelegate?.categoryPredicate {
            request.predicate = predicate
        } else {
            request.predicate = NSPredicate(format: "completedDate == nil")
        }
        
        toDoFetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        toDoFetchedResultsController.delegate = self
        
        do {
            try toDoFetchedResultsController.performFetch()
            if let toDos = toDoFetchedResultsController.fetchedObjects as? [ToDo] {
                fetchedToDos = toDos
            }
        } catch {
            fatalError("Failed to initialize fetch")
        }
    }
    
    func getToDo(moID: NSManagedObjectID?) -> ToDo? {
        guard let managedObjectID = moID else { return nil }
        guard let theToDo = dataController.managedObjectContext.object(with: managedObjectID) as? ToDo else { return nil }
        return theToDo
    }
    
    func save(addedToDoTitle: String, newToDoSidebarSelection: SidebarItem?) {
        if addedToDoTitle.isEmpty {
            print("do not add a new to do item")
        } else {
            guard let theToDo = NSEntityDescription.insertNewObject(forEntityName: "ToDo", into: dataController.managedObjectContext) as? ToDo else { return }
            theToDo.title = addedToDoTitle
            theToDo.createdDate = NSDate()
            if let sbCat = (newToDoSidebarSelection as? SidebarCategoryItem)?.sbCategory {
                theToDo.group = sbCat
            }
            dataController.saveMoc()
            mainTableViewDelgate?.reloadData()
        }
    }

    func markCompleted(atIndex index: Int, complete: Bool) {
        guard let fetchedObjs = toDoFetchedResultsController.fetchedObjects else { return }
        guard let object = fetchedObjs[index] as? ToDo else { return }
        if complete {
            object.completedDate = NSDate()
        } else {
            object.completedDate = nil
        }
        if toDoModelAcessor.managedContextDidSave() {
            mainTableViewDelgate?.removeRows(atIndex: index)
            initializeToDoFetchedResultsController()
        } else {
            mainTableViewDelgate?.reloadData()
        }
        
    }
    
    func removeToDoEntityRecord(atIndex: Int) {
        print("removing to do record")
//        guard let fetchedObjs = toDoFetchedResultsController.fetchedObjects else { return }
//        guard let object = fetchedObjs[atIndex] as? NSManagedObject else { return }
//        dataController.managedObjectContext.delete(object)
//        dataController.saveMoc()
//        mainTableViewDelgate?.reloadData()
    }
    
    func updateNote(newNote: String, moID: NSManagedObjectID?) {
        guard let theToDo = getToDo(moID: moID) else { return }
        theToDo.note = newNote
        dataController.saveMoc()
    }
    
    
    // MARK: - Update View
    func completedWasChecked(state: Int, btnIndex index: Int, withManagedObjectID moID: NSManagedObjectID) {
        switch state {
        case 1:
            markCompleted(atIndex: index, complete: true)
        case 0:
            markCompleted(atIndex: index, complete: false)
        default:
            break
        }
    }
    
    func assigneToDoToGroup(moID: NSManagedObjectID, group: Group) {
        guard let theToDo = getToDo(moID: moID) else { return }
        theToDo.group = group
        dataController.saveMoc()
    }
    
    func setToDaily(moID: NSManagedObjectID, isDaily: Bool) {
        if let toDo = getToDo(moID: moID) {
            toDo.daily = isDaily
            dataController.saveMoc()
            mainTableViewDelgate?.reloadData()
        }
    }
    
    //MARK: - Table View Menu Delegate Functions
    func setMenuDailyState(sender: NSMenuItem) {
        guard let mTvDel = mainTableViewDelgate else { return }
        guard let clickedToDo = mTvDel.clickedToDo else { return }
        
        if clickedToDo.daily {
            sender.state = .on
        } else {
            sender.state = .off
        }
    }

}
