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

class MainController: NSObject, NSTableViewDelegate, NSTableViewDataSource, ToDoCellViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate {
    let registeredTypes:[String] = [NSGeneralPboard]
    let appDelegate = NSApplication.shared().delegate as? AppDelegate
    var managedContext: NSManagedObjectContext? = nil
    var coreDataToDoManagedObjects: [NSManagedObject]? = nil
    var mainTableToDoArray: [ToDo] = []
    var currentSelectionToDoArray: [ToDo] = []
    weak var mainTableViewDelgate: MainTableViewDelgate?
    
    var outlineGroups = ["All", "Daily", "Domo", "Vertica", "ServiceNow", "Data Query", "Home"]
    
    fileprivate enum CellIdentifiers {
        static let col_complete = "col_complete"
        static let col_toDoText = "col_toDoText"
    }
    
    override init() {
        super.init()
        
        managedContext = self.appDelegate?.persistentContainer.viewContext
        coreDataToDoManagedObjects = fetchManagedObjectsFromCoreData(entityName: "ToDo")
        mainTableToDoArray = populateMainTableToDoArray()
        currentSelectionToDoArray = mainTableToDoArray
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
        let currentSidebarGroup = obj.value(forKey: "sidebarGroup") as? String
        let currentManagedContextID = obj.objectID
        
        let currentToDo = ToDo(title:           currentTitle,
                               completed:       currentCompleted,
                               ordinalPosition: currentOrdinalPosition,
                               sidebarGroup:    currentSidebarGroup,
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
        
        if managedContextDidSave(managedContext: mc) {
            coreDataToDoManagedObjects = fetchManagedObjectsFromCoreData(entityName: entityName)
            mainTableToDoArray.append(createToDoFromManagedObject(obj: toDoEntityRecord))
            mainTableViewDelgate?.reloadData()
            mainTableViewDelgate?.updateStatusBar(numOfItems: mainTableToDoArray.count)
        }
    }

    
    func removeToDoEntityRecord(atIndex: Int) {
        guard let context = self.managedContext else { return }
        guard let toDoMO = coreDataToDoManagedObjects else { return }
        context.delete(toDoMO[atIndex])
        if managedContextDidSave(managedContext: context) {
            coreDataToDoManagedObjects!.remove(at: atIndex)
            mainTableToDoArray.remove(at: atIndex)
            mainTableViewDelgate?.reloadData()
            mainTableViewDelgate?.updateStatusBar(numOfItems: mainTableToDoArray.count)
        }
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
    
    func changeSidebarGroup(atIndex: Int, toGroup: String) {
        guard let mc = self.managedContext else { return }
        guard let cdObj = coreDataToDoManagedObjects?[atIndex] else { return }
        cdObj.setValue(toGroup, forKey: "sidebarGroup")
        if managedContextDidSave(managedContext: mc) {
            mainTableToDoArray[atIndex].sidebarGroup = toGroup
        }
    }
    
    // MARK: - To Do Table View Delegate Methods
    func changeText(newToDoTitle: String, atIndex: Int) {
        guard let mc = managedContext else { return }
        guard let cdObj = coreDataToDoManagedObjects?[atIndex] else { return }
        cdObj.setValue(newToDoTitle, forKey: "title")
        if managedContextDidSave(managedContext: mc) {
            mainTableToDoArray[atIndex].title = newToDoTitle
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

        if managedContextDidSave(managedContext: mc) {
            coreDataToDoManagedObjects = fetchManagedObjectsFromCoreData(entityName: "ToDo")
            mainTableViewDelgate?.reloadData()
        }
    }
    
    // MARK: - Table View Methods
    func numberOfRows(in tableView: NSTableView) -> Int {
        return currentSelectionToDoArray.count
    }
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let theToDo = currentSelectionToDoArray[row]
        
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
            cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? ToDoCellView
            if let cell = cell as? ToDoCellView {
                cell.toDoCellViewDelegate = self
                cell.index = row
                cell.textField?.stringValue = theToDo.title
                cell.textField?.isEditable = true
            } else {
                print("Could not cast cell as ToDoCellView")
            }
        }
        
        return cell!
    }
    
    func doubleClickMainTVCell(sender: AnyObject) {
        guard let tv = sender as? NSTableView else { return }
        if tv.selectedRow  == -1 {
            print("Double clicked empty cell")
        } else {
            let doubleClickedToDo = mainTableToDoArray[tv.selectedRow]
            print(doubleClickedToDo)
        }
        
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return NSDragOperation(rawValue: UInt(0))
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.declareTypes(registeredTypes, owner: self)
        pboard.setData(data, forType: NSGeneralPboard)
        return true
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
                   dropOperation: NSTableViewDropOperation) -> Bool {
        let dragData = info.draggingPasteboard().data(forType: NSGeneralPboard)!
        let rowIndexes: IndexSet? = NSKeyedUnarchiver.unarchiveObject(with: dragData) as? IndexSet
        guard let ri: IndexSet = rowIndexes else { return true }
        let dragOrigin = ri.first!
        let dragDest = row
        reorderToDos(dragOrigin: dragOrigin, dragDest: dragDest)
        mainTableViewDelgate?.reloadData()
        return true
    }
    
    
    // MARK: - OutlineView Methods
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let object = notification.object as? NSOutlineView else { return }
        if outlineGroups[object.selectedRow] == "All" {
            currentSelectionToDoArray = mainTableToDoArray
        } else {
            currentSelectionToDoArray = mainTableToDoArray.filter {
                $0.sidebarGroup == outlineGroups[object.selectedRow]
            }
        }
        mainTableViewDelgate?.reloadData()
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return outlineGroups.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return outlineGroups[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.make(withIdentifier: "DataCell", owner: self) as! NSTableCellView
        if let textField = view.textField {
            textField.stringValue = item as! String
        }
        return view
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        if let item = item as? String {
            if item == "All" {
                return NSDragOperation(rawValue: UInt(0))
            }
            return .move
        }
        return NSDragOperation(rawValue: UInt(0))
    }
    
    func outlineView(_ outlineView: NSOutlineView, writeItems items: [Any], to pasteboard: NSPasteboard) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let pboard = info.draggingPasteboard()
        let dragData = pboard.data(forType: NSGeneralPboard)!
        let rowIndexes: IndexSet? = NSKeyedUnarchiver.unarchiveObject(with: dragData) as? IndexSet
        guard let dragOrigin: Int = rowIndexes?.first else { return false }
        guard let sidebarGroup = item as? String else { return false }
        
        changeSidebarGroup(atIndex: dragOrigin, toGroup: sidebarGroup)
        
        return true
    }
}
