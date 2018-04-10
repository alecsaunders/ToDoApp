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


protocol MainTableViewDelgate: class {
    func reloadData()
    func reloadSidebar()
    func addToDoToGroup(toDoRowIndex: Int, group: Group)
    func setToDoToDaily(toDoRowIndex: Int)
    func updateStatusBar(numOfItems: Int, sidebarGroup: String?)
    func doubleClick(sender: AnyObject)
    var clickedToDo: ToDo? { get }
}

class MainController: NSObject, NSTableViewDelegate, NSTableViewDataSource, NSFetchedResultsControllerDelegate, InfoControllerDelegate, ToDoCellViewDelegate, TableViewMenuDelegate {
    let registeredTypes = [NSPasteboard.PasteboardType.string]
    let dataController = DataController()
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    weak var mainTableViewDelgate: MainTableViewDelgate?
    var sidebarPredicate: NSPredicate?
    
    override init() {
        super.init()
        
        sidebarPredicate = NSPredicate(format: "completedDate == nil")
        initializeFetchedResultsController()
    }
    
    
    //REPLACE THIS FUNCTION IS A SUBCLASS OF fetchedGroupsController
    func mapFetchedGroupsToSidebarCategory(groupArray: [Group]) -> [SidebarCategoryItem] {
        let sbCatArray: [SidebarCategoryItem] = groupArray.map { (theGroup) -> SidebarCategoryItem in
            let sbCat = SidebarCategoryItem(withTitle: theGroup.groupName!)
            sbCat.sbCategory = theGroup
            return sbCat
        }
        
        return sbCatArray
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
        
        if let predicate = sidebarPredicate {
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
    
    //MARK: - TableView Delegate Methods
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let fetchedObjs = fetchedResultsController.fetchedObjects as? [ToDo] else { return 0 }
        mainTableViewDelgate?.updateStatusBar(numOfItems: fetchedObjs.count, sidebarGroup: nil)
        return fetchedObjs.count
    }
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let fetchedObjs = fetchedResultsController.fetchedObjects as? [ToDo] else { return nil }
        let theToDo = fetchedObjs[row]
        
        if tableColumn == tableView.tableColumns[0] {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "col_complete"), owner: nil) as? NSTableCellView else { return nil }
            if let completeBtn = cell.subviews[0] as? NSButton {
                if let _ = theToDo.completedDate {
                    completeBtn.state = NSControl.StateValue.on
                } else {
                    completeBtn.state = NSControl.StateValue.off
                }
                completeBtn.tag = row
            }
            return cell
        }
        if tableColumn == tableView.tableColumns[1] {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "col_toDoText"), owner: nil) as? ToDoCellView else { return nil }
            if let theTitle = theToDo.title {
                cell.textField?.stringValue = theTitle
            }
            cell.toDoCellViewDelegate = self
            cell.managedObjectID = theToDo.objectID
            
            return cell
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return NSDragOperation(rawValue: UInt(0))
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.declareTypes(registeredTypes, owner: self)
        pboard.setData(data, forType: .string)
        return true
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        let dragData = info.draggingPasteboard().data(forType: .string)!
        let rowIndexes: IndexSet? = NSKeyedUnarchiver.unarchiveObject(with: dragData) as? IndexSet
        guard let ri: IndexSet = rowIndexes else { return true }
        let dragOrigin = ri.first!
        let dragDest = row
        print(dragOrigin)
        print(dragDest)
        return false
    }
    
    // MARK: - To Do Table View Delegate Methods
    func changeText(newToDoTitle: String, moID: NSManagedObjectID) {
        guard let toDoObj = getToDo(moID: moID) else { return }
        toDoObj.setValue(newToDoTitle, forKey: "title")
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
