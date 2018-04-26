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

protocol CategoryDelegate {
    var categoryPredicate: NSPredicate? { get set }
}

class OutlineViewController: NSObject, NSFetchedResultsControllerDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, GroupCellViewDelegate, CategoryDelegate {
    let dataController = DataController()
    weak var mainTableViewDelgate: MainTableViewDelgate?
    var mainControllerDelegate: MainControllerDelegate?
    var fetchedGroupsController: NSFetchedResultsController<NSFetchRequestResult>!
    var categoryPredicate: NSPredicate?

    var sbFilterSection: SidebarSection {
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
        return SidebarSection(name: "Filters", sbItem: filters)
    }
    var sbCategorySection: SidebarSection = SidebarSection(name: "Categories", sbItem: [])
    var sbCatArray: [SidebarCategoryItem] = []
    
    override init() {
        super.init()
        initializeFetchedGroupsController()
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
            guard let fetchedGroups = fetchedGroupsController.fetchedObjects as? [Group] else { return }
            let sbCatArray = mapFetchedGroupsToSidebarCategory(groupArray: fetchedGroups)
            sbCategorySection.sbItem = sbCatArray
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
                categoryPredicate = compPred
            }
        }
        
        if let cat = sidebarView.item(atRow: sidebarView.selectedRow) as? SidebarFilterItem {
            if let filter = cat.sbFilter {
                switch filter {
                case .daily:
                    let dailyPred = NSPredicate(format: "daily = %@", "1")
                    let completePred = NSPredicate(format: "completedDate == nil")
                    let compPred = NSCompoundPredicate(andPredicateWithSubpredicates: [dailyPred, completePred])
                    categoryPredicate = compPred
                case .completed:
                    categoryPredicate = NSPredicate(format: "completedDate != nil")
                default:
                    categoryPredicate = NSPredicate(format: "completedDate == nil")
                }
            } else {
                categoryPredicate = NSPredicate(format: "completedDate == nil")
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
//        if let sbItem = item as? SidebarItem {
//            if let sbFilterItem = sbItem as? SidebarFilterItem {
//                if sbFilterItem.sbFilter == SidebarFilter.all {
//                    return NSDragOperation(rawValue: UInt(0))
//                }
//            }
//            return .move
//        }
        
        if let _ = item as? SidebarCategoryItem {
            return .move
        }
        
        return NSDragOperation(rawValue: UInt(0))
    }
    
    func outlineView(_ outlineView: NSOutlineView, writeItems items: [Any], to pasteboard: NSPasteboard) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        return nil
    }
    
    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let pboard = info.draggingPasteboard()
        guard let pbItem = pboard.pasteboardItems?[0] else { return false }
        guard let managedObjectIDURLString = pbItem.string(forType: .string) else { return false }
        guard let objectID = URL(string: managedObjectIDURLString) else { return false }
        guard let managedObjectID = dataController.persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: objectID) else { return false }
        guard let sbCat = (item as? SidebarCategoryItem)?.sbCategory else { return false }
        mainControllerDelegate?.assigneToDoToGroup(moID: managedObjectID, group: sbCat)
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
        mainTableViewDelgate?.reloadSidebar()
    }
    
    func deleteSidebarGroup(group: Group) {
        dataController.managedObjectContext.delete(group)
        dataController.saveMoc()
        initializeFetchedGroupsController()
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
