//
//  OutlineViewController.swift
//  Todo
//
//  Created by Alec Saunders on 4/8/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Foundation
import Cocoa
import CoreData

class OutlineViewController: NSObject, NSFetchedResultsControllerDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, GroupCellViewDelegate {
    let dataController = DataController()
    weak var mainTableViewDelgate: MainTableViewDelgate?
    var fetchedGroupsController: NSFetchedResultsController<NSFetchRequestResult>!
    var sidebarPredicate: NSPredicate?

    var sbFilterSection: SidebarSection
    var sbCategorySection: SidebarSection
    
    override init() {
        var filters: [SidebarItem] = []
        let allFilter = SidebarFilterItem(withTitle: "All")
        allFilter.sbFilter = .all
        let dailyFilter = SidebarFilterItem(withTitle: "Daily")
        dailyFilter.sbFilter = .daily
        let completedFilter = SidebarFilterItem(withTitle: "Completed")
        completedFilter.sbFilter = .completed
        filters.append(allFilter)
        filters.append(dailyFilter)
        filters.append(completedFilter)
        
        sbFilterSection = SidebarSection(name: "Filters", sbItem: filters)
        sbCategorySection = SidebarSection(name: "Categories", sbItem: [])
        
        super.init()
        
        sidebarPredicate = NSPredicate(format: "completedDate == nil")
        initializeFetchedGroupsController()

        guard let fetchedGroups = fetchedGroupsController.fetchedObjects as? [Group] else { return }
        let sbCatArray = mapFetchedGroupsToSidebarCategory(groupArray: fetchedGroups)
        
        sbCategorySection.sbItem = sbCatArray
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
    
    // MARK: - OutlineView Methods
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        if let _ = item as? SidebarSection {
            return false
        }
        return true
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let sidebarView = notification.object as? NSOutlineView else { return }
        
        if let sbCatItem = sidebarView.item(atRow: sidebarView.selectedRow) as? SidebarCategoryItem {
            if let selectedGroup = sbCatItem.sbCategory {
                let groupPred = NSPredicate(format: "group = %@", selectedGroup)
                let completePred = NSPredicate(format: "completedDate == nil")
                let compPred = NSCompoundPredicate(andPredicateWithSubpredicates: [groupPred, completePred])
                sidebarPredicate = compPred
            }
        }
        
        if let cat = sidebarView.item(atRow: sidebarView.selectedRow) as? SidebarFilterItem {
            if let filter = cat.sbFilter {
                switch filter {
                case .daily:
                    let dailyPred = NSPredicate(format: "daily = %@", "1")
                    let completePred = NSPredicate(format: "completedDate == nil")
                    let compPred = NSCompoundPredicate(andPredicateWithSubpredicates: [dailyPred, completePred])
                    mainTableViewDelgate?.testSidebarPredicate = compPred
                case .completed:
                    mainTableViewDelgate?.testSidebarPredicate = NSPredicate(format: "completedDate != nil")
                default:
                    mainTableViewDelgate?.testSidebarPredicate = NSPredicate(format: "completedDate == nil")
                }
            } else {
                mainTableViewDelgate?.testSidebarPredicate = NSPredicate(format: "completedDate == nil")
            }
            
        }
        print("outlineview selection did change")
        mainTableViewDelgate?.reloadData()
    }
    
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let item = item {
            switch item {
            case let sbSection as SidebarSection:
                return sbSection.sbItem.count
            default:
                return 0
            }
        } else {
            return 2 //Filters , Categories
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        switch item {
        case let sbSection as SidebarSection:
            return (sbSection.sbItem.count > 0) ? true : false
        default:
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item {
            switch item {
            case let sbSection as SidebarSection:
                return sbSection.sbItem[index]
            default:
                return self
            }
        } else {
            switch index {
            case 0:
                return sbFilterSection
            default:
                return sbCategorySection
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
        case let sbSection as SidebarSection:
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as! NSTableCellView
            if let textField = view.textField {
                textField.stringValue = sbSection.name
            }
            return view
        case let sbItem as SidebarFilterItem:
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as! NSTableCellView
            view.textField?.stringValue = sbItem.sidebarTitle
            return view
        case let sbCat as SidebarCategoryItem:
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as! GroupCellView
            view.groupID = sbCat.sbCategory!.objectID
            view.groupCellViewDelegate = self
            if let textField = view.txtGroup {
                textField.isEditable = true
                textField.stringValue = sbCat.sbCategory!.groupName!
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
    
    // MARK: - Other Methods
    func addSidebarGroup(groupName: String) {
        guard let newGroup = NSEntityDescription.insertNewObject(forEntityName: "Group", into: dataController.managedObjectContext) as? Group else { return }
        newGroup.groupName = groupName
        dataController.saveMoc()
        initializeFetchedGroupsController()
        guard let fetchedGroups = fetchedGroupsController.fetchedObjects as? [Group] else { return }
        let sbCatItems = mapFetchedGroupsToSidebarCategory(groupArray: fetchedGroups)
        sbCategorySection.sbItem = sbCatItems
        mainTableViewDelgate?.reloadSidebar()
    }
    
    func deleteSidebarGroup(group: Group) {
        dataController.managedObjectContext.delete(group)
        dataController.saveMoc()
        initializeFetchedGroupsController()
        guard let fetchedGroups = fetchedGroupsController.fetchedObjects as? [Group] else { return }
        let sbCatItems = mapFetchedGroupsToSidebarCategory(groupArray: fetchedGroups)
        sbCategorySection.sbItem = sbCatItems
        mainTableViewDelgate?.reloadSidebar()
    }
    
    func changeSidebarTitle(newTitle: String, moID: NSManagedObjectID) {
        let groupObj = dataController.managedObjectContext.object(with: moID)
        groupObj.setValue(newTitle, forKey: "groupName")
        dataController.saveMoc()
        initializeFetchedGroupsController()
        mainTableViewDelgate?.reloadSidebar()
    }
}
