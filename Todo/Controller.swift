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
    func reloadData(sidebarGroup: String)
    func updateStatusBar(numOfItems: Int)
    func doubleClick(sender: AnyObject)
}

class MainController: NSObject, NSTableViewDelegate, NSTableViewDataSource, ToDoCellViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate {
    let registeredTypes:[String] = [NSGeneralPboard]
    let modelAccessor = ToDoModelAccessor()
    var mainTableToDoArray: [ToDo] = []
    var currentSelectionToDoArray: [ToDo] = []
    var currentSource = "All"
    weak var mainTableViewDelgate: MainTableViewDelgate?
    
    var outlineGroups = ["All", "Daily", "Domo", "Vertica", "ServiceNow", "Data Query", "Home"]
    
    fileprivate enum CellIdentifiers {
        static let col_complete = "col_complete"
        static let col_toDoText = "col_toDoText"
    }
    
    override init() {
        super.init()
        
        mainTableToDoArray = modelAccessor.populateMainTableToDoArray()
        currentSelectionToDoArray = mainTableToDoArray
    }
    
    func save(currentToDoTitle: String) {
        if currentToDoTitle.isEmpty { return }
        if let newToDo = modelAccessor.createNewToDo(title: currentToDoTitle, ordinalPosition: mainTableToDoArray.count) {
            mainTableToDoArray.append(newToDo)
            mainTableViewDelgate?.reloadData(sidebarGroup: currentSource)
            mainTableViewDelgate?.updateStatusBar(numOfItems: mainTableToDoArray.count)
        }
    }

    
    func removeToDoEntityRecord(atIndex: Int) {
        let theCompletedToDo = currentSelectionToDoArray[atIndex]
        if modelAccessor.deleteManagedObject(moID: theCompletedToDo.managedContextID) {
            currentSelectionToDoArray.remove(at: atIndex)
            mainTableToDoArray = mainTableToDoArray.filter { $0.managedContextID != theCompletedToDo.managedContextID }
            mainTableViewDelgate?.reloadData(sidebarGroup: currentSource)
            mainTableViewDelgate?.updateStatusBar(numOfItems: mainTableToDoArray.count)
        }
    }
    
    func changeSidebarGroup(atIndex: Int, toGroup: String) {
        let changedToDoId = currentSelectionToDoArray[atIndex].managedContextID
        if modelAccessor.updateSidebarGroup(moID: changedToDoId, newGroup: toGroup) {
            currentSelectionToDoArray[atIndex].sidebarGroup = toGroup
            for i in 0..<mainTableToDoArray.count {
                if mainTableToDoArray[i].managedContextID == changedToDoId {
                    mainTableToDoArray[i].sidebarGroup = toGroup
                }
            }
        }
    }
    
    func updateCurrentSelectionToDoArray(group: String) {
        if group == "All" {
            currentSelectionToDoArray = mainTableToDoArray
            currentSelectionToDoArray = currentSelectionToDoArray.sorted { $0.createdDate < $1.createdDate }
        } else {
            currentSelectionToDoArray = mainTableToDoArray.filter {
                $0.sidebarGroup == group
            }
            currentSelectionToDoArray = currentSelectionToDoArray.sorted { $0.ordinalPosition < $1.ordinalPosition }
        }
    }
    
    // MARK: - To Do Table View Delegate Methods
    func changeText(newToDoTitle: String, atIndex: Int) {
        let changedToDoId = currentSelectionToDoArray[atIndex].managedContextID
        if modelAccessor.updateTitle(moID: changedToDoId, newTitle: newToDoTitle) {
            currentSelectionToDoArray[atIndex].title = newToDoTitle
            for i in 0..<mainTableToDoArray.count {
                if mainTableToDoArray[i].managedContextID == changedToDoId {
                    mainTableToDoArray[i].title = newToDoTitle
                }
            }
        }
    }
    
    
    // MARK: - Update View
    func completedWasChecked(state: Int, btnIndex: Int) {
        switch state {
        case NSOnState:
            removeToDoEntityRecord(atIndex: btnIndex)
        case NSOffState:
            break
        default:
            break
        }
    }
    
    func reorderToDos(dragOrigin: Int, dragDest: Int) {
        var alteredDragDest = dragDest
        if dragOrigin == dragDest - 1 { return }
        if dragOrigin < dragDest {
            alteredDragDest = dragDest - 1
        }
        
        let draggedItem = currentSelectionToDoArray[dragOrigin]
        currentSelectionToDoArray.remove(at: dragOrigin)
        currentSelectionToDoArray.insert(draggedItem, at: alteredDragDest)
        
        for i in 0..<currentSelectionToDoArray.count {
            currentSelectionToDoArray[i].ordinalPosition = i
            for j in 0..<mainTableToDoArray.count {
                if mainTableToDoArray[j].managedContextID == currentSelectionToDoArray[i].managedContextID {
                    mainTableToDoArray[j].ordinalPosition = i
                }
            }
        }
        for i in 0..<currentSelectionToDoArray.count {
            let moID = currentSelectionToDoArray[i].managedContextID
            modelAccessor.updatePosition(moID: moID, newPosition: i)
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
            let doubleClickedToDo = currentSelectionToDoArray[tv.selectedRow]
            print(doubleClickedToDo)
        }
        
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        if currentSource == "All" {
            return NSDragOperation(rawValue: UInt(0))
        }
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
        if currentSource != "All" {
            let dragData = info.draggingPasteboard().data(forType: NSGeneralPboard)!
            let rowIndexes: IndexSet? = NSKeyedUnarchiver.unarchiveObject(with: dragData) as? IndexSet
            guard let ri: IndexSet = rowIndexes else { return true }
            let dragOrigin = ri.first!
            let dragDest = row
            reorderToDos(dragOrigin: dragOrigin, dragDest: dragDest)
            mainTableViewDelgate?.reloadData(sidebarGroup: currentSource)
            return true
        }
        return false

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
        currentSource = outlineGroups[object.selectedRow]
        mainTableViewDelgate?.reloadData(sidebarGroup: currentSource)
        mainTableViewDelgate?.updateStatusBar(numOfItems: currentSelectionToDoArray.count)
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
