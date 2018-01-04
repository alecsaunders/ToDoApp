//
//  TableViewController.swift
//  Todo
//
//  Created by Alec Saunders on 10/1/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

//protocol MainTableViewDelgate: class {
//    func reloadData()
//    func reloadSidebar()
//    func addToDoToGroup(toDoRowIndex: Int, group: Group)
//    func setToDoToDaily(toDoRowIndex: Int)
//    func updateStatusBar(numOfItems: Int)
//    func doubleClick(sender: AnyObject)
//    var clickedToDo: ToDo? { get }
//}

class TableViewController: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    let registeredTypes = [NSPasteboard.PasteboardType.string]
    let dataController = DataController()
    
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
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let fetchedObjs = fetchedResultsController.fetchedObjects as? [ToDo] else { return 0 }
        mainTableViewDelgate?.updateStatusBar(numOfItems: fetchedObjs.count)
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
}
