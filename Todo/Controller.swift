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
    func updateStatusBar(numOfItems: Int)
    func doubleClick(sender: AnyObject)
}

class MainController: NSObject, NSTableViewDelegate, NSTableViewDataSource {
    let registeredTypes:[String] = [NSGeneralPboard]
    let appDelegate = NSApplication.shared().delegate as? AppDelegate
    var managedContext: NSManagedObjectContext? = nil
    var coreDataToDoManagedObjects: [NSManagedObject]? = nil
    var mainTableToDoArray: [ToDo] = []
    weak var mainTableViewDelgate: MainTableViewDelgate?
    
    fileprivate enum CellIdentifiers {
        static let col_complete = "col_complete"
        static let col_toDoText = "col_toDoText"
    }
    
    override init() {
        super.init()
        
        managedContext = self.appDelegate?.persistentContainer.viewContext
        coreDataToDoManagedObjects = fetchManagedObjectsFromCoreData(entityName: "ToDo")
        mainTableToDoArray = populateMainTableToDoArray()
    }
    
    // MARK: - Core Data Setup
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
    
    func save(currentToDoTitle: String) {
        if currentToDoTitle.isEmpty { return }
        
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
            mainTableViewDelgate?.reloadData()
            mainTableViewDelgate?.updateStatusBar(numOfItems: mainTableToDoArray.count)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
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
            mainTableViewDelgate?.reloadData()
            mainTableViewDelgate?.updateStatusBar(numOfItems: mainTableToDoArray.count)
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
        }
    }
    
    
    // MARK: - Update View
    func completedWasChecked(state: Int, btnIndex: Int) {
        switch state {
        case NSOnState:
            removeToDoEntityRecord(atIndex: btnIndex)
            mainTableViewDelgate?.reloadData()
        case NSOffState:
            break
        default:
            break
        }
    }
    
    func reorderToDos(dragOrigin: Int, dragDest: Int) {
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
            mainTableViewDelgate?.reloadData()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    // MARK: - Table View Methods
    func numberOfRows(in tableView: NSTableView) -> Int {
        return mainTableToDoArray.count
    }
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let theToDo = mainTableToDoArray[row]
        
        var cellIdentifier: String = ""
        
        var cell: NSTableCellView? = nil
        
        if tableColumn == tableView.tableColumns[0] {
            cellIdentifier = CellIdentifiers.col_complete
            cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
            if let completedCheck = cell?.subviews[0] as? NSButton {
                completedCheck.tag = row
                completedCheck.state = theToDo.completed ? 1 : 0
            }
        } else if tableColumn == tableView.tableColumns[1] {
            cellIdentifier = CellIdentifiers.col_toDoText
            cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = theToDo.title
            cell?.textField?.isEditable = true
        }
        
        return cell!
    }
    
    func doubleClickMainTVCell(sender: AnyObject) {
        guard let tv = sender as? NSTableView else { return }
        print(tv.selectedRow)
        let doubleClickedToDo = mainTableToDoArray[tv.selectedRow]
        print(doubleClickedToDo)
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return .every
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.declareTypes(registeredTypes, owner: self)
        pboard.setData(data, forType: NSGeneralPboard)
        return true
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        let dragData = info.draggingPasteboard().data(forType: NSGeneralPboard)!
        let rowIndexes: IndexSet? = NSKeyedUnarchiver.unarchiveObject(with: dragData) as? IndexSet
        guard let ri: IndexSet = rowIndexes else { return true }
        let dragOrigin = ri.first!
        let dragDest = row
        reorderToDos(dragOrigin: dragOrigin, dragDest: dragDest)
        mainTableViewDelgate?.reloadData()
        return true
    }
}
