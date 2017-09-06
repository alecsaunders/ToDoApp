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

class MainController: NSObject, NSTableViewDelegate, NSTableViewDataSource, NSFetchedResultsControllerDelegate, ToDoCellViewDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, InfoControllerDelegate {
    let registeredTypes:[String] = [NSGeneralPboard]
    let dataController = DataController()
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    weak var mainTableViewDelgate: MainTableViewDelgate?
    
    var department1 = Department(name: "Categories", groups: [])
    var department2 = Department(name: "Favorites", groups: [])
    
    //var outlineGroups = ["All", "Daily", "Domo", "Vertica", "ServiceNow", "Data Query", "Home"]
    var sidebarGroups: [Group] = []
    
    override init() {
        super.init()
        initializeFetchedResultsController()
        
        
//        var allGroup = Group(groupName: "All")
//        allGroup.system = true
//        var dailyGroup = Group(groupName: "Daily")
//        dailyGroup.system = true
//        var completedGroup = Group(groupName: "Completed")
//        completedGroup.system = true
        
//        department1.groups.append(allGroup)
//        department1.groups.append(dailyGroup)
//        department1.groups.append(completedGroup)
        department2.groups = sidebarGroups
    }
    
    func initializeFetchedResultsController() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "ToDo")
        let sort = NSSortDescriptor(key: "createdDate", ascending: false)
        request.sortDescriptors = [sort]
        let moc = dataController.managedObjectContext
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
            saveMoc()
            initializeFetchedResultsController()
            mainTableViewDelgate?.reloadData()
        }

    }

    func removeToDoEntityRecord(atIndex: Int) {
        guard let fetchedObjs = fetchedResultsController.fetchedObjects else { return }
        guard let object = fetchedObjs[atIndex] as? NSManagedObject else { return }
        dataController.managedObjectContext.delete(object)
        saveMoc()
        initializeFetchedResultsController()
        mainTableViewDelgate?.reloadData()
    }
    
    func saveMoc() {
        do {
            try dataController.managedObjectContext.save()
        } catch {
            print("failed to save new to do")
        }
    }
    
    func changeSidebarGroup(atIndex: Int, toGroup: String) {
        print("change sidebar group")
    }
    
    func updateCurrentSelectionToDoArray(group: String) {
        print("update current selection to do array")
    }
    
    func updateNote(newNote: String, moID: NSManagedObjectID) {
        print("update")
//        if modelAccessor.updateNote(newNote: newNote, moID: moID) {
//            for i in 0..<mainTableToDoArray.count {
//                if mainTableToDoArray[i].managedContextID == moID {
//                    mainTableToDoArray[i].note = newNote
//                }
//            }
//        }
    }
    
    //MARK: - TableView Delegate Methods
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let fetchedObjs = fetchedResultsController.fetchedObjects as? [ToDo] else { return 0 }
        return fetchedObjs.count
    }
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let fetchedObjs = fetchedResultsController.fetchedObjects as? [ToDo] else { return nil }
        let theToDo = fetchedObjs[row]
        
        if tableColumn == tableView.tableColumns[0] {
            guard let cell = tableView.make(withIdentifier: "col_complete", owner: nil) as? NSTableCellView else { return nil }
            if let completeBtn = cell.subviews[0] as? NSButton {
                completeBtn.state = theToDo.completed.hashValue
                completeBtn.tag = row
            }
            return cell
        }
        if tableColumn == tableView.tableColumns[1] {
            guard let cell = tableView.make(withIdentifier: "col_toDoText", owner: nil) as? ToDoCellView else { return nil }
            if let theTitle = theToDo.title {
                cell.textField?.stringValue = theTitle
            }
            cell.toDoCellViewDelegate = self
            cell.index = row
            cell.managedObjectID = theToDo.objectID
            
            return cell
        }
        
        return nil
    }
        
    
    // MARK: - To Do Table View Delegate Methods
    func changeText(newToDoTitle: String, moID: NSManagedObjectID) {
        let toDoObj = dataController.managedObjectContext.object(with: moID)
        toDoObj.setValue(newToDoTitle, forKey: "title")
        saveMoc()
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
    
//    func reorderToDos(dragOrigin: Int, dragDest: Int) {
//        var alteredDragDest = dragDest
//        if dragOrigin == dragDest - 1 { return }
//        if dragOrigin < dragDest {
//            alteredDragDest = dragDest - 1
//        }
//        
//        let draggedItem = mainTableToDoArray[dragOrigin]
//        mainTableToDoArray.remove(at: dragOrigin)
//        mainTableToDoArray.insert(draggedItem, at: alteredDragDest)
//        
//        for i in 0..<mainTableToDoArray.count {
//            let moID = mainTableToDoArray[i].managedContextID
//            modelAccessor.updatePosition(moID: moID, newPosition: i)
//        }
//    }
    
    // MARK: - OutlineView Methods
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let sidebarView = notification.object as? NSOutlineView else { return }
        guard let item = sidebarView.item(atRow: sidebarView.selectedRow) as? Group else { return }

    }
    
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item {
            switch item {
            case let department as Department:
                return department.groups.count
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
            return (department.groups.count > 0) ? true : false
        default:
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item {
            switch item {
            case let department as Department:
                return department.groups[index]
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
        case let group as Group:
            let view = outlineView.make(withIdentifier: "DataCell", owner: self) as! GroupCellView
//            view.groupID = group.groupID
            if let textField = view.txtGroup {
                textField.stringValue = group.groupName!
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
        print("Add sidebar group")
    }
    
    func deleteSidebarGroup(group: Group) {
        print("Delete sidebar group")
//        guard let moID = group.groupID else { return }
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
