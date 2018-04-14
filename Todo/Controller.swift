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
    weak var mainTableViewDelgate: MainTableViewDelgate?
    
    override init() {
        super.init()
    }
    
    func getToDo(moID: NSManagedObjectID?) -> ToDo? {
        guard let managedObjectID = moID else { return nil }
        guard let theToDo = dataController.managedObjectContext.object(with: managedObjectID) as? ToDo else { return nil }
        return theToDo
    }
    
    func save(addedToDoTitle: String) {
        if addedToDoTitle.isEmpty {
            print("do not add a new to do item")
        } else {
            guard let theToDo = NSEntityDescription.insertNewObject(forEntityName: "ToDo", into: dataController.managedObjectContext) as? ToDo else { return }
            theToDo.title = addedToDoTitle
            theToDo.createdDate = NSDate()
            dataController.saveMoc()
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
        mainTableViewDelgate?.reloadData()
    }
    
    func removeToDoEntityRecord(atIndex: Int) {
        guard let fetchedObjs = fetchedResultsController.fetchedObjects else { return }
        guard let object = fetchedObjs[atIndex] as? NSManagedObject else { return }
        dataController.managedObjectContext.delete(object)
        dataController.saveMoc()
        
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
