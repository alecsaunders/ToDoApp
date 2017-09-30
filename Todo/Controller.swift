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
    func updateStatusBar(numOfItems: Int)
    func doubleClick(sender: AnyObject)
    var clickedToDo: ToDo? { get }
}

class MainController: NSObject, NSTableViewDelegate, NSTableViewDataSource, NSFetchedResultsControllerDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, InfoControllerDelegate, ToDoCellViewDelegate, GroupCellViewDelegate, TableViewMenuDelegate {
    let registeredTypes = [NSPasteboard.PasteboardType.string]
    let dataController = DataController()
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    var fetchedGroupsController: NSFetchedResultsController<NSFetchRequestResult>!
    weak var mainTableViewDelgate: MainTableViewDelgate?
    var sidebarPredicate: NSPredicate?
    
    var department1: Department<String> = Department(name: "Categories", groups: SidebarCategory().groups)
    var department2: Department<Group> = Department(name: "Favorites", groups: [])
    
    override init() {
        super.init()
        
        sidebarPredicate = NSPredicate(format: "completedDate == nil")
        
        initializeFetchedResultsController()
        initializeFetchedGroupsController()
        
        guard let fetchedGroups = fetchedGroupsController.fetchedObjects as? [Group] else { return }
        
        department2.groups = fetchedGroups
    }
    
    func getToDo(moID: NSManagedObjectID) -> ToDo? {
        guard let theToDo = dataController.managedObjectContext.object(with: moID) as? ToDo else { return nil }
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
    
    func initializeFetchedGroupsController() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Group")
        let sort = NSSortDescriptor(key: "groupName", ascending: true)
        request.sortDescriptors = [sort]
        let moc = dataController.managedObjectContext
        fetchedGroupsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedGroupsController.delegate = self
        
        do {
            try fetchedGroupsController.performFetch()
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
            saveMoc()
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
        object.completed = complete
        saveMoc()
        initializeFetchedResultsController()
        mainTableViewDelgate?.reloadData()
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
    
    func updateNote(newNote: String, moID: NSManagedObjectID) {
        guard let theToDo = getToDo(moID: moID) else { return }
        theToDo.note = newNote
        saveMoc()
    }
    
    //MARK: - TableView Delegate Methods
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
                completeBtn.state = NSControl.StateValue(rawValue: theToDo.completed.hashValue)
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
        saveMoc()
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

    
    // MARK: - OutlineView Methods
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let sidebarView = notification.object as? NSOutlineView else { return }
        if let selectedGroup = sidebarView.item(atRow: sidebarView.selectedRow) as? Group {
            let groupPred = NSPredicate(format: "group = %@", selectedGroup)
            let completePred = NSPredicate(format: "completedDate == nil")
            let compPred = NSCompoundPredicate(andPredicateWithSubpredicates: [groupPred, completePred])
            sidebarPredicate = compPred
        }
        
        if let cat = sidebarView.item(atRow: sidebarView.selectedRow) as? String {
            switch cat {
            case "Daily":
                let dailyPred = NSPredicate(format: "daily = %@", "1")
                let completePred = NSPredicate(format: "completedDate == nil")
                let compPred = NSCompoundPredicate(andPredicateWithSubpredicates: [dailyPred, completePred])
                sidebarPredicate = compPred
            case "Completed":
                sidebarPredicate = NSPredicate(format: "completedDate != nil")
            default:
                sidebarPredicate = NSPredicate(format: "completedDate == nil")
            }
        }
        initializeFetchedResultsController()
        mainTableViewDelgate?.reloadData()
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item {
            switch item {
            case let department as Department<String>:
                return department.groups.count
            case let department as Department<Group>:
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
        case _ as Department<String>:
            return true
        case let department as Department<Group>:
            return (department.groups.count > 0) ? true : false
        default:
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item {
            switch item {
            case let department as Department<String>:
                return department.groups[index]
            case let department as Department<Group>:
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
    
    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        switch item {
        case _ as Department<String>:
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as! NSTableCellView
            if let textField = view.textField {
                textField.stringValue = "Categories"
            }
            return view
        case let department as Department<Group>:
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as! NSTableCellView
            if let textField = view.textField {
                textField.stringValue = department.name
            }
            return view
        case let group as String:
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as! NSTableCellView
            view.textField?.stringValue = group
            return view
        case let group as Group:
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as! GroupCellView
            view.groupID = group.objectID
            view.groupCellViewDelegate = self
            if let textField = view.txtGroup {
                textField.isEditable = true
                textField.stringValue = group.groupName!
            }
            return view
        default:
            return nil
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        if let _ = item as? Group {
            return .move
        }
        if let cat = item as? String {
            if cat == "Daily" {
                return .move
            }
        }
        return NSDragOperation(rawValue: UInt(0))
    }

    func outlineView(_ outlineView: NSOutlineView, writeItems items: [Any], to pasteboard: NSPasteboard) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let pboard = info.draggingPasteboard()
        let dragData = pboard.data(forType: .string)!
        let rowIndexes: IndexSet? = NSKeyedUnarchiver.unarchiveObject(with: dragData) as? IndexSet
        guard let dragOrigin: Int = rowIndexes?.first else { return false }
        if let sidebarGroup = item as? Group {
            mainTableViewDelgate?.addToDoToGroup(toDoRowIndex: dragOrigin, group: sidebarGroup)
        }
        if let cat = item as? String {
            if cat == "Daily" {
                mainTableViewDelgate?.setToDoToDaily(toDoRowIndex: dragOrigin)
            }
        }
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return false
    }
    
    func assigneToDoToGroup(moID: NSManagedObjectID, group: Group) {
        guard let theToDo = getToDo(moID: moID) else { return }
        theToDo.group = group
        saveMoc()
    }
    
    func addSidebarGroup(groupName: String) {
        guard let newGroup = NSEntityDescription.insertNewObject(forEntityName: "Group", into: dataController.managedObjectContext) as? Group else { return }
        newGroup.groupName = groupName
        saveMoc()
        initializeFetchedGroupsController()
        guard let fetchedGroups = fetchedGroupsController.fetchedObjects as? [Group] else { return }
        department2.groups = fetchedGroups
        mainTableViewDelgate?.reloadSidebar()
    }
    
    func deleteSidebarGroup(group: Group) {
        dataController.managedObjectContext.delete(group)
        saveMoc()
        initializeFetchedGroupsController()
        guard let fetchedGroups = fetchedGroupsController.fetchedObjects as? [Group] else { return }
        department2.groups = fetchedGroups
        mainTableViewDelgate?.reloadSidebar()
    }
    
    func changeSidebarTitle(newTitle: String, moID: NSManagedObjectID) {
        let groupObj = dataController.managedObjectContext.object(with: moID)
        groupObj.setValue(newTitle, forKey: "groupName")
        saveMoc()
        initializeFetchedGroupsController()
        mainTableViewDelgate?.reloadSidebar()
    }
    
    func setToDaily(moID: NSManagedObjectID, isDaily: Bool) {
        if let toDo = getToDo(moID: moID) {
            toDo.daily = isDaily
            saveMoc()
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
