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

class MainController: NSObject, NSTableViewDelegate, NSTableViewDataSource, ToDoCellViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, InfoControllerDelegate {
    let registeredTypes:[String] = [NSGeneralPboard]
    let modelAccessor = ToDoModelAccessor()
    var mainTableToDoArray: [ToDo] = []
    var currentSource = "All"
    weak var mainTableViewDelgate: MainTableViewDelgate?
    
    var department1 = Department (name:"Categories")
    var department2 = Department (name:"Favorites")
    
    var outlineGroups = ["All", "Daily", "Domo", "Vertica", "ServiceNow", "Data Query", "Home"]
    var sidebarGroups: [Group] = []
    
    fileprivate enum CellIdentifiers {
        static let col_complete = "col_complete"
        static let col_toDoText = "col_toDoText"
    }
    
    override init() {
        super.init()
        
        sidebarGroups = modelAccessor.populateSidebarGroupsArray()
        mainTableToDoArray = modelAccessor.populateMainTableToDoArray()
        
        var allGroup = Group(groupName: "All")
        allGroup.system = true
        var dailyGroup = Group(groupName: "Daily")
        dailyGroup.system = true
        var completedGroup = Group(groupName: "Completed")
        completedGroup.system = true
        
        department1.accounts.append(allGroup)
        department1.accounts.append(dailyGroup)
        department1.accounts.append(completedGroup)
        department2.accounts = sidebarGroups
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
        let theCompletedToDo = mainTableToDoArray[atIndex]
        if modelAccessor.deleteManagedObject(moID: theCompletedToDo.managedContextID) {
            mainTableToDoArray.remove(at: atIndex)
            mainTableViewDelgate?.reloadData(sidebarGroup: currentSource)
            mainTableViewDelgate?.updateStatusBar(numOfItems: mainTableToDoArray.count)
        }
    }
    
    func changeSidebarGroup(atIndex: Int, toGroup: String) {
        print("change sidebar group")
    }
    
    func updateCurrentSelectionToDoArray(group: String) {
        print("update current selection to do array")
    }
    
    func updateNote(newNote: String, moID: NSManagedObjectID) {
        if modelAccessor.updateNote(newNote: newNote, moID: moID) {
            for i in 0..<mainTableToDoArray.count {
                if mainTableToDoArray[i].managedContextID == moID {
                    mainTableToDoArray[i].note = newNote
                }
            }
        }
    }
    
    // MARK: - To Do Table View Delegate Methods
    func changeText(newToDoTitle: String, atIndex: Int) {
        let changedToDoId = mainTableToDoArray[atIndex].managedContextID
        if modelAccessor.updateTitle(moID: changedToDoId, newTitle: newToDoTitle) {
            mainTableToDoArray[atIndex].title = newToDoTitle
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
        
        let draggedItem = mainTableToDoArray[dragOrigin]
        mainTableToDoArray.remove(at: dragOrigin)
        mainTableToDoArray.insert(draggedItem, at: alteredDragDest)
        
        for i in 0..<mainTableToDoArray.count {
            let moID = mainTableToDoArray[i].managedContextID
            modelAccessor.updatePosition(moID: moID, newPosition: i)
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
        guard let sidebarView = notification.object as? NSOutlineView else {
            print("could not cast as outline view")
            return
        }
        guard let item = sidebarView.item(atRow: sidebarView.selectedRow) as? Group else {
            print("could not cast as group")
            return
        }
        guard let itemID = item.groupID else { return }
        print(itemID)
//        if sidebarGroups[object.selectedRow].groupName == "All" {
//            currentSelectionToDoArray = mainTableToDoArray
//        } else {
//            currentSelectionToDoArray = mainTableToDoArray.filter {
//                $0.sidebarGroup == sidebarGroups[object.selectedRow].groupName
//            }
//        }
//        currentSource = sidebarGroups[object.selectedRow].groupName
//        mainTableViewDelgate?.reloadData(sidebarGroup: currentSource)
//        mainTableViewDelgate?.updateStatusBar(numOfItems: currentSelectionToDoArray.count)
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item {
            switch item {
            case let department as Department:
                return department.accounts.count
            default:
                return 0
            }
        } else {
            return 2 //Department1 , Department 2
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        switch item {
        case let department as Department:
            return (department.accounts.count > 0) ? true : false
        default:
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item {
            switch item {
            case let department as Department:
                return department.accounts[index]
            default:
                return self
            }
        } else {
            switch index {
            case 0:
                return department1
            default:
                return department2
            }
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        switch item {
        case let department as Department:
            let view = outlineView.make(withIdentifier: "HeaderCell", owner: self) as! NSTableCellView
            if let textField = view.textField {
                textField.stringValue = department.name
            }
            return view
        case let account as Group:
            let view = outlineView.make(withIdentifier: "DataCell", owner: self) as! GroupCellView
            view.groupID = account.groupID
            if let textField = view.txtGroup {
                if !account.system {
                    textField.isEditable = true
                }
                textField.stringValue = account.groupName
            }
            return view
        default:
            return nil
        }
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
    
    func expandOutlineViewNodes(outlineView: NSOutlineView) {
        for i in 0...outlineView.numberOfRows {
            let child = outlineView.item(atRow: i)
            outlineView.expandItem(child)
        }
        for i in 0...outlineView.numberOfRows {
            let child = outlineView.item(atRow: i)
            outlineView.expandItem(child)
        }
    }
    
    func addSidebarGroup(groupName: String) {
        if let newGroup = modelAccessor.createNewGroup(groupName: groupName) {
            sidebarGroups.append(newGroup)
            department2.accounts = sidebarGroups
        }
    }
    
    func deleteSidebarGroup(group: Group) {
        guard let moID = group.groupID else { return }
//        for i in 0..<sidebarGroups.count {
//            if sidebarGroups[i].groupID == moID {
//                if modelAccessor.deleteManagedObject(moID: moID) {
//                    sidebarGroups = modelAccessor.populateSidebarGroupsArray()
//                    department2.accounts = sidebarGroups
//                }
//            }
//        }
    }
}
