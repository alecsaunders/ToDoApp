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
}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, MainTableViewDelgate, WindowControllerDelegate {
    let registeredTypes = [NSPasteboard.PasteboardType.string]
    var clickedToDo: ToDo? {
        get {
            return cntlr.getToDo(fromTableView: mainTableView)
        }
    }
    @IBOutlet var mainTableView: NSTableView!
    @IBOutlet var lblStatusBottom: NSTextField!
    @IBOutlet weak var sourceSidebar: NSScrollView!
    @IBOutlet var sidebarView: NSView!
    @IBOutlet weak var sourceOutlineView: NSOutlineView!
    @IBOutlet var tvMenu: TvMenu!
    
    var mtvdel2: MTVDel2?
    var cntlr: MainController!
    let outlineCntlr = OutlineViewController()
    
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
        outlineCntlr.categoryDelegate = cntlr.firebaseController
        outlineCntlr.mainTableViewDelgate = self
        sourceOutlineView.delegate = outlineCntlr
        sourceOutlineView.dataSource = outlineCntlr
        sourceOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        sourceOutlineView.registerForDraggedTypes([.string])
        sourceOutlineView?.expandItem(nil, expandChildren: true)
        outlineCntlr.mainControllerDelegate = cntlr
    }
    
    @IBAction func sidebarMenuDelete(_ sender: NSMenuItem) {
        guard let sbCatItem = sourceOutlineView.item(atRow: sourceOutlineView.clickedRow) as? SidebarCategoryItem else { return }
        guard let sbCat = sbCatItem.sbCategory else { return }
        outlineCntlr.deleteSidebarGroup(group: sbCat)
        sourceOutlineView.reloadData()
        sourceOutlineView?.expandItem(nil, expandChildren: true)
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
        let txt = windowConroller.toDoCreateTextField.stringValue
        cntlr.save(addedToDoTitle: txt, newToDoSidebarSelection: sourceOutlineView.item(atRow: sourceOutlineView.selectedRow) as? SidebarItem)
        windowConroller.toDoCreateTextField.stringValue = ""
    }
    @IBAction func btnAddGroup(_ sender: NSButton) {
        outlineCntlr.addSidebarGroup(groupName: "New Group")
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
        sourceOutlineView.reloadData()
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
        cntlr.save(addedToDoTitle: toDoText, newToDoSidebarSelection: sourceOutlineView.item(atRow: sourceOutlineView.selectedRow) as? SidebarItem)
    }
    
    // MARK: - Controller functions
    func updateStatusBar(withText text: String) {
        lblStatusBottom.stringValue = text
    }
}
