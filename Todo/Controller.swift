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


class MainController: NSObject, NSFetchedResultsControllerDelegate, InfoControllerDelegate, TableViewMenuDelegate {
    let registeredTypes = [NSPasteboard.PasteboardType.string]
    let dataController = DataController()
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    weak var mainTableViewDelgate: MainTableViewDelgate?
    
    override init() {
        super.init()
        
        mainTableViewDelgate?.testSidebarPredicate = NSPredicate(format: "completedDate == nil")
        initializeFetchedResultsController()
    }
    
    func getToDo(moID: NSManagedObjectID?) -> ToDo? {
        guard let managedObjectID = moID else { return nil }
        guard let theToDo = dataController.managedObjectContext.object(with: managedObjectID) as? ToDo else { return nil }
        return theToDo
    }
    
    func initializeFetchedResultsController() {
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
        
        if let predicate = mainTableViewDelgate?.testSidebarPredicate {
            request.predicate = predicate
        }
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize fetch")
        }
    }
    
    func save(addedToDoTitle: String) {
        if addedToDoTitle.isEmpty {
            print("do not add a new to do item")
        } else {
            guard let theToDo = NSEntityDescription.insertNewObject(forEntityName: "ToDo", into: dataController.managedObjectContext) as? ToDo else { return }
            theToDo.title = addedToDoTitle
            theToDo.createdDate = NSDate()
            dataController.saveMoc()
            initializeFetchedResultsController()
            // FIXME: The initializeFetchedResultsController initalizes the new fetched ToDos for the Controller method, but the MainTableViewController FetchedResultsController has not fetched the new to dos.
            mainTableViewDelgate?.reloadData()
        }
    }

    func markCompleted(atIndex: Int, complete: Bool) {
        guard let fetchedObjs = fetchedResultsController.fetchedObjects else { return }
        guard let object = fetchedObjs[atIndex] as? ToDo else { return }
        if complete {
            object.completedDate = NSDate()
        } else {
            object.completedDate = nil
        }
        dataController.saveMoc()
        initializeFetchedResultsController()
        mainTableViewDelgate?.reloadData()
    }
    
    func removeToDoEntityRecord(atIndex: Int) {
        guard let fetchedObjs = fetchedResultsController.fetchedObjects else { return }
        guard let object = fetchedObjs[atIndex] as? NSManagedObject else { return }
        dataController.managedObjectContext.delete(object)
        dataController.saveMoc()
        
        initializeFetchedResultsController()
        mainTableViewDelgate?.reloadData()
    }
    
    func updateNote(newNote: String, moID: NSManagedObjectID?) {
        guard let theToDo = getToDo(moID: moID) else { return }
        theToDo.note = newNote
        dataController.saveMoc()
    }
    
    
    // MARK: - Update View
    func completedWasChecked(state: Int, btnIndex: Int) {
        switch state {
        case 1:
            markCompleted(atIndex: btnIndex, complete: true)
        case 0:
            markCompleted(atIndex: btnIndex, complete: false)
            break
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
            initializeFetchedResultsController()
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
