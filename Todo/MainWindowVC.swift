//
//  ViewController.swift
//  Todo
//
//  Created by Alec Saunders on 8/13/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa
import CoreData


protocol MainTableViewDelgate: class {
    func reloadData()
    func reloadSidebar()
    func addToDoToGroup(toDoRowIndex: Int, group: Group)
    func setToDoToDaily(toDoRowIndex: Int)
    func updateStatusBar(withText text: String)
    var clickedToDo: ToDo? { get }
}

protocol MTVDel2 {
    var fetchedToDos: [ToDo] { get set }
    var fetchedGroups: [Group] { get set }
}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSOutlineViewDataSource, NSOutlineViewDelegate, MainTableViewDelgate, WindowControllerDelegate {
    @IBOutlet var mainTableView: NSTableView!
    @IBOutlet var lblStatusBottom: NSTextField!
    @IBOutlet weak var sourceSidebar: NSScrollView!
    @IBOutlet var sidebarView: NSView!
    @IBOutlet weak var sourceOutlineView: NSOutlineView!
    @IBOutlet var tvMenu: TvMenu!
    let registeredTypes = [NSPasteboard.PasteboardType.string]
    var clickedToDo: ToDo? {
        get {
            return cntlr.getToDo(fromTableView: mainTableView)
        }
    }
    var mtvdel2: MTVDel2?
    var cntlr: MainController!
    
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
    
    override func viewWillAppear() {
        if let windowConroller = self.view.window?.windowController as? WindowController {
            windowConroller.windowControllerDelegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cntlr = MainController()
        cntlr.mainTableViewDelgate = self
        mtvdel2 = cntlr.firebaseController
        
        setupPrefs()
        setupMainTableView()
        setupSourceOutlineView()

        tvMenu.tvMenuDelegate = cntlr
        lblStatusBottom.textColor = NSColor.darkGray

    }
    
    func setupPrefs() {
        let notificationName = Notification.Name(rawValue: "PrefsChanged")
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { (notification) in
            self.mainTableView.usesAlternatingRowBackgroundColors = self.cntlr.mainTableViewSetAlternatingRows()
        }
    }
    
    func setupMainTableView() {
        mainTableView.delegate = self
        mainTableView.dataSource = self
        mainTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        mainTableView.registerForDraggedTypes(registeredTypes)
        mainTableView.doubleAction = #selector(self.doubleClick)
        mainTableView.usesAlternatingRowBackgroundColors = cntlr.mainTableViewSetAlternatingRows()
        mainTableView.reloadData()
    }
    
    func setupSourceOutlineView() {
        sourceOutlineView.delegate = self
        sourceOutlineView.dataSource = self
        sourceOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        sourceOutlineView.registerForDraggedTypes([.string])
        sourceOutlineView?.expandItem(nil, expandChildren: true)
    }
    
    @IBAction func sidebarMenuDelete(_ sender: NSMenuItem) {
        guard let sbCatItem = sourceOutlineView.item(atRow: sourceOutlineView.clickedRow) as? SidebarCategoryItem else { return }
        cntlr.deleteSidebarCategory(withCategoryItem: sbCatItem)
    }
    
    @IBAction func menuDaily(_ sender: NSMenuItem) {
        guard let theToDo = cntlr.getToDo(fromTableView: mainTableView) else { return }
        cntlr.setToDaily(toDo: theToDo, isDaily: !theToDo.daily)
    }
    
    @IBAction func markComplete(_ sender: NSMenuItem) {
        guard let clicked_view = mainTableView.view(atColumn: 0, row: mainTableView.clickedRow, makeIfNecessary: false) as? NSTableCellView  else { return }
        guard let button = clicked_view.subviews[0] as? NSButton else { return }
        changeState(ofButton: button)
        completedCheck(button)
    }
    func changeState(ofButton button: NSButton) {
        switch button.state {
        case .on:
            button.state = .off
        case .off:
            button.state = .on
        default:
            print("Cannot change state")
        }
    }
    @IBAction func completedCheck(_ sender: NSButton) {
        cntlr.completedWasChecked(atIndex: sender.tag, withState: sender.state.rawValue)
    }
    
    @IBAction func btnAddItem(_ sender: NSButton) {
        guard let windowConroller = self.view.window?.windowController as? WindowController else { return }
        addToDo(toDoText: windowConroller.toDoCreateTextField.stringValue)
    }
    
    @IBAction func btnAddGroup(_ sender: NSButton) {
        cntlr.saveNewGroup(withName: "New Group")
    }
    
    // Show Info View Controller
    @IBAction func menuGetInfo(_ sender: NSMenuItem) {
        showInfoViewController()
    }
    @objc func doubleClick(sender: AnyObject) {
        showInfoViewController()
    }
    func showInfoViewController() {
        guard mainTableView.clickedRow >= 0 else { return }
        performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "infoSegue"), sender: self)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let dest = segue.destinationController as? InfoViewController else { return }
        guard let theToDo = cntlr.getToDo(fromTableView: mainTableView) else { return }
        cntlr.setupInfoSegue(dest: dest, withToDo: theToDo)
        dest.infoControllerDelegate = cntlr
    }
    
    func animate(hide: Bool) {
        sidebarView.animator().isHidden = hide
    }
    
    func reloadData() {
        mainTableView.reloadData()
    }
    
    func reloadSidebar() {
        guard let mtvd2 = mtvdel2 else { return }
        sbCategorySection.sbItem = []
        sbCategorySection.sbItem = mapGroupsToSidebarCategories(groupList: mtvd2.fetchedGroups)
        sourceOutlineView.reloadData()
        sourceOutlineView?.expandItem(nil, expandChildren: true)
    }
    
    func mapGroupsToSidebarCategories(groupList list: [Group]) -> [SidebarCategoryItem] {
        let sidebarCategories = list.map { (g) -> SidebarCategoryItem in
            let newSbCatItem = SidebarCategoryItem(withTitle: g.groupName)
            newSbCatItem.sbCategory = g
            return newSbCatItem
        }
        return sidebarCategories
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let mtv2 = mtvdel2 else { return 0 }
        updateStatusBar(withText: cntlr.getStatusLabel(withNumber: mtv2.fetchedToDos.count, forGroup: nil))
        return mtv2.fetchedToDos.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let mtv2 = mtvdel2 else { return nil }
        let theToDo = mtv2.fetchedToDos[row]
        if tableColumn == tableView.tableColumns[0] {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "col_complete"),
                                                owner: nil) as? NSTableCellView else { return nil }
            guard let completeBtn = cell.subviews[0] as? NSButton else { return nil }
            completeBtn.tag = row
            completeBtn.state = theToDo.completedDate != nil ? .on : .off
            return cell
        }
        if tableColumn == tableView.tableColumns[1] {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "col_toDoText"),
                                                owner: nil) as? ToDoCellView else { return nil }
            cell.cellToDo = theToDo
            cell.textField?.stringValue = cell.cellToDo!.title
            cell.toDoCellViewDelegate = cntlr
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
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        //        let pbItem = NSPasteboardItem()
        //        guard let moID = mainTableViewDelgate?.toDoManagedObjectID(index: row) else { return nil }
        //
        //        pbItem.setString(moID.uriRepresentation().absoluteString, forType: .string)
        //        pbItem.setData(moID.uriRepresentation().dataRepresentation, forType: .URL)
        //        return pbItem
        return nil
    }
    
    func addToDoToGroup(toDoRowIndex: Int, group: Group) {
        guard let toDo = cntlr.getToDo(fromTableView: mainTableView) else { return }
        cntlr.firebaseController.update(toDo: toDo, property: "group", with: group.groupName)
    }
    
    func setToDoToDaily(toDoRowIndex: Int) {
        guard let theToDo = cntlr.getToDo(fromTableView: mainTableView) else { return }
        cntlr.setToDaily(toDo: theToDo, isDaily: !theToDo.daily)
    }
    
    // MARK: - Window Controller Delegate
    func addToDo(toDoText: String) {
        cntlr.saveNewToDo(withTitle: toDoText, withSidebarItem: sourceOutlineView.item(atRow: sourceOutlineView.selectedRow) as? SidebarItem)
    }
    
    // MARK: - Controller functions
    func updateStatusBar(withText text: String) {
        lblStatusBottom.stringValue = text
    }
    
    // --------------------------- \\
    // MARK: - OutlineView Methods
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
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item {
            switch item {
            case let sbSection as SidebarSection:
                let child = sbSection.sbItem[index]
                return child
            default:
                return self
            }
        } else {
            switch index {
            case 0:
                return sbFilterSection
            case 1:
                return sbCategorySection
            default:
                return sbCategorySection
            }
        }
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
            guard let group = sbCat.sbCategory else {
                print("failed to get group from sbcat")
                return nil
            }
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as! GroupCellView
            view.groupID = group.groupID
            view.groupCellViewDelegate = cntlr
            if let textField = view.txtGroup {
                textField.isEditable = true
                textField.stringValue = group.groupName
            }
            return view
        default:
            print("Default")
            return nil
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        //        print("Is item expandable")
        //        return true
        //        switch item {
        //        case let sbSection as SidebarSection:
        //            return (sbSection.sbItem.count > 0) ? true : false
        //        default:
        //            return false
        //        }
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldExpandItem item: Any) -> Bool {
        return true
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        if let _ = item as? SidebarSection {
            return false
        }
        return true
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let sidebarView = notification.object as? NSOutlineView else { return }
        guard let sbItem = sidebarView.item(atRow: sidebarView.selectedRow) as? SidebarItem  else { return }
        cntlr.firebaseController.updateMainView(with: sbItem)
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
        //        let pboard = info.draggingPasteboard()
        //        guard let pbItem = pboard.pasteboardItems?[0] else { return false }
        //        guard let managedObjectIDURLString = pbItem.string(forType: .string) else { return false }
        //        guard let objectID = URL(string: managedObjectIDURLString) else { return false }
        //        guard let managedObjectID = dataController.persistentContainer.persistentStoreCoordinator.managedObjectID(forURIRepresentation: objectID) else { return false }
        //        guard let sbCat = (item as? SidebarCategoryItem)?.sbCategory else { return false }
        //        mainControllerDelegate?.assigneToDoToGroup(moID: managedObjectID, group: sbCat)
        //        return true
        return false // placeholder value
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        return false
    }
}
