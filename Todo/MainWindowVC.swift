//
//  ViewController.swift
//  Todo
//
//  Created by Alec Saunders on 8/13/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa
import CoreData


class ViewController: NSViewController, MainTableViewDelgate, WindowControllerDelegate {
    let registeredTypes:[String] = [NSPasteboard.Name.general.rawValue]
    var clickedToDo: ToDo? {
        get {
            guard let v = mainTableView.view(atColumn: 1, row: mainTableView.clickedRow, makeIfNecessary: false) as? ToDoCellView else { return nil }
            guard let moID = v.managedObjectID else { return nil }
            guard let theToDo = cntlr.getToDo(moID: moID) else { return nil }
            return theToDo
        }
    }
    @IBOutlet var mainTableView: NSTableView!
    @IBOutlet var lblStatusBottom: NSTextField!
    @IBOutlet weak var sourceSidebar: NSScrollView!
    @IBOutlet var sidebarView: NSView!
    @IBOutlet weak var sourceOutlineView: NSOutlineView!
    @IBAction func btnAddItem(_ sender: NSButton) {
        if let windowConroller = self.view.window?.windowController as? WindowController {
            let txt = windowConroller.toDoCreateTextField.stringValue
            cntlr.save(addedToDoTitle: txt, newToDoSidebarSelection: sourceOutlineView.item(atRow: sourceOutlineView.selectedRow) as? SidebarItem)
            windowConroller.toDoCreateTextField.stringValue = ""
        }
    }
    @IBAction func btnAddGroup(_ sender: NSButton) {
        outlineCntlr.addSidebarGroup(groupName: "New Group")
    }
    @IBAction func completedCheck(_ sender: NSButton) {
//        markToDoComplete(withSenderState: sender.state.rawValue)
        guard let moID = (mainTableView.view(atColumn: 1, row: sender.tag, makeIfNecessary: false) as? ToDoCellView)?.managedObjectID else { return }
        cntlr.completedWasChecked(state: sender.state.rawValue, btnIndex: sender.tag, withManagedObjectID: moID)
    }
    @IBOutlet var tvMenu: TvMenu!
    @IBAction func markComplete(_ sender: NSMenuItem) {
//        markToDoComplete(withSenderState: sender.state.rawValue)
        guard let moID = (mainTableView.view(atColumn: 1, row: mainTableView.clickedRow, makeIfNecessary: false) as? ToDoCellView)?.managedObjectID else { return }
        cntlr.completedWasChecked(state: sender.state.rawValue, btnIndex: mainTableView.clickedRow, withManagedObjectID: moID)
    }
    @IBAction func menuGetInfo(_ sender: NSMenuItem) {
        if mainTableView.clickedRow >= 0 {
            performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "infoSegue"), sender: self)
        }
    }
    @IBAction func menuDaily(_ sender: NSMenuItem) {
        guard let moID = (mainTableView.view(atColumn: 1, row: mainTableView.clickedRow, makeIfNecessary: false) as? ToDoCellView)?.managedObjectID else { return }
        guard let theToDo = cntlr.getToDo(moID: moID) else { return }
        if theToDo.daily {
            cntlr.setToDaily(moID: moID, isDaily: false)
        } else {
            cntlr.setToDaily(moID: moID, isDaily: true)
        }
    }
    @IBAction func sidebarMenuDelete(_ sender: NSMenuItem) {
        guard let sbCatItem = sourceOutlineView.item(atRow: sourceOutlineView.clickedRow) as? SidebarCategoryItem else { return }
        guard let sbCat = sbCatItem.sbCategory else { return }
        outlineCntlr.deleteSidebarGroup(group: sbCat)
        sourceOutlineView.reloadData()
        sourceOutlineView?.expandItem(nil, expandChildren: true)
    }

    let cntlr = MainController()
    let tvCntlr = MainTableViewController()
    let outlineCntlr = OutlineViewController()
    
    override func viewWillAppear() {
        if let windowConroller = self.view.window?.windowController as? WindowController {
            windowConroller.windowControllerDelegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPrefs()
        
        cntlr.mainTableViewDelgate = self
        tvCntlr.mtvdel2 = cntlr
                
        tvCntlr.mainTableViewDelgate = self
        lblStatusBottom.textColor = NSColor.darkGray
        mainTableView.delegate = tvCntlr
        mainTableView.dataSource = tvCntlr
        mainTableViewSetAlternatingRows()
        mainTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        mainTableView.registerForDraggedTypes(tvCntlr.registeredTypes)
        mainTableView.doubleAction = #selector(self.doubleClick)
        mainTableView.reloadData()
        
        outlineCntlr.mainTableViewDelgate = self
        sourceOutlineView.delegate = outlineCntlr
        sourceOutlineView.dataSource = outlineCntlr
        sourceOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        sourceOutlineView.registerForDraggedTypes([.string])
        sourceOutlineView?.expandItem(nil, expandChildren: true)
        
        cntlr.categoryDelegate = outlineCntlr
        outlineCntlr.mainControllerDelegate = cntlr
        
        tvMenu.tvMenuDelegate = cntlr
    }
    
    func setupPrefs() {        
        let notificationName = Notification.Name(rawValue: "PrefsChanged")
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { (notification) in
            let userDefaults = NSUserDefaultsController().defaults
            self.mainTableView.usesAlternatingRowBackgroundColors = userDefaults.bool(forKey: "alternateRows")
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let dest = segue.destinationController as? InfoViewController else { return }
        guard let moID = (mainTableView.view(atColumn: 1, row: mainTableView.clickedRow, makeIfNecessary: false) as? ToDoCellView)?.managedObjectID else { return }
        guard let theToDo = cntlr.getToDo(moID: moID) else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let clickedCreateDate = theToDo.createdDate! as Date
        let clickedCreateDateString = dateFormatter.string(from: clickedCreateDate)
        dest.infoTitleString = theToDo.title
        dest.intoCreatedDateString = clickedCreateDateString
        dest.note = theToDo.note
        dest.managedObjectID = theToDo.objectID
        dest.infoControllerDelegate = cntlr
    }
    
    func mainTableViewSetAlternatingRows() {
        let userDefaults = NSUserDefaultsController().defaults
        let alternateBool = userDefaults.bool(forKey: "alternateRows")
        mainTableView.usesAlternatingRowBackgroundColors = alternateBool
    }
    
    
    func animate(hide: Bool) {
        sourceSidebar.animator().isHidden = hide
        sidebarView.animator().isHidden = hide
    }
    
    
    func markToDoComplete(withSenderState state: Int) {
        let clickedRow = mainTableView.clickedRow
        print(clickedRow)
        guard let moID = (mainTableView.view(atColumn: 1, row: clickedRow, makeIfNecessary: false) as? ToDoCellView)?.managedObjectID else { return }
        cntlr.completedWasChecked(state: state, btnIndex: clickedRow, withManagedObjectID: moID)
    }
    
    // MARK: - Main Table View Delegate Functions
    @objc func doubleClick(sender: AnyObject) {
        if mainTableView.clickedRow >= 0 {
            performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "infoSegue"), sender: self)
        }
        if let v = mainTableView.view(atColumn: 1, row: mainTableView.clickedRow, makeIfNecessary: false) as? ToDoCellView {
            if let toDo = cntlr.dataController.managedObjectContext.object(with: v.managedObjectID!) as? ToDo {
//                let isoDate = "2017-08-25T04:55:00+0000"
//
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
//                let date = dateFormatter.date(from:isoDate)! as NSDate
//
//                toDo.completedDate = date
                print(toDo)
            }
        }
    }
    
    func reloadData() {
        cntlr.initializeToDoFetchedResultsController()
        mainTableView.reloadData()
    }
    
    func toDoManagedObjectID(index: Int) -> NSManagedObjectID? {
        guard let toDoCellView = mainTableView.view(atColumn: 1, row: index, makeIfNecessary: false) as? ToDoCellView else { return nil }
        return toDoCellView.managedObjectID
    }
    
    func addToDoToGroup(toDoRowIndex: Int, group: Group) {
        guard let moID = (mainTableView.view(atColumn: 1, row: toDoRowIndex, makeIfNecessary: false) as? ToDoCellView)?.managedObjectID else { return }
        cntlr.assigneToDoToGroup(moID: moID, group: group)
    }
    
    func setToDoToDaily(toDoRowIndex: Int) {
        guard let moID = (mainTableView.view(atColumn: 1, row: toDoRowIndex, makeIfNecessary: false) as? ToDoCellView)?.managedObjectID else { return }
        cntlr.setToDaily(moID: moID, isDaily: true)
    }
    
    func reloadSidebar() {
        outlineCntlr.initializeFetchedGroupsController()
        sourceOutlineView.reloadData()
        sourceOutlineView?.expandItem(nil, expandChildren: true)
    }
    
    func removeRows(atIndex index: Int) {
        print("removeRows")
        if let rView = mainTableView.view(atColumn: 1, row: index, makeIfNecessary: false) as? ToDoCellView {
            if let rToDo = cntlr.dataController.managedObjectContext.object(with: rView.managedObjectID!) as? ToDo {
                print(rToDo)
            }
        } else {
            print("No ToDoCellView at index \(index)")
        }
        
        mainTableView.beginUpdates()
        let removedIndecies = IndexSet.init(integer: index)
        mainTableView.removeRows(at: removedIndecies, withAnimation: .slideUp)
        mainTableView.endUpdates()
    }
    
    // MARK: - Window Controller Delegate
    func addToDo(toDoText: String) {
        cntlr.save(addedToDoTitle: toDoText, newToDoSidebarSelection: sourceOutlineView.item(atRow: sourceOutlineView.selectedRow) as? SidebarItem)
    }
    func clearToDoTextField(sender: NSTextField) {
        sender.stringValue = ""
    }
    
    // MARK: - Controller functions
    func updateStatusBar(withText text: String) {
        lblStatusBottom.stringValue = text
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
    }
}
