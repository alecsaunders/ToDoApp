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
            guard let theToDo = cntlr.getToDo(moID: nil) else { return nil }
            return theToDo
        }
    }
    @IBOutlet var mainTableView: NSTableView!
    @IBOutlet var lblStatusBottom: NSTextField!
    @IBOutlet weak var sourceSidebar: NSScrollView!
    @IBOutlet var sidebarView: NSView!
    @IBOutlet weak var sourceOutlineView: NSOutlineView!
    @IBOutlet var tvMenu: TvMenu!
    var cntlr: MainController!
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
        
        cntlr = MainController()
        cntlr.mainTableViewDelgate = self
        cntlr.reloadUI()
        tvCntlr.mtvdel2 = cntlr.firebaseController
        tvCntlr.mainTableViewDelgate = self
        lblStatusBottom.textColor = NSColor.darkGray
        
        mainTableView.delegate = tvCntlr
        mainTableView.dataSource = tvCntlr
        
        mainTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        mainTableView.registerForDraggedTypes(tvCntlr.registeredTypes)
        mainTableView.doubleAction = #selector(self.doubleClick)
        mainTableView.reloadData()
        mainTableView.usesAlternatingRowBackgroundColors = cntlr.mainTableViewSetAlternatingRows()
        outlineCntlr.categoryDelegate = cntlr.firebaseController
        outlineCntlr.mainTableViewDelgate = self
        sourceOutlineView.delegate = outlineCntlr
        sourceOutlineView.dataSource = outlineCntlr
        sourceOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        sourceOutlineView.registerForDraggedTypes([.string])
        sourceOutlineView?.expandItem(nil, expandChildren: true)
        
        outlineCntlr.mainControllerDelegate = cntlr
        
        tvMenu.tvMenuDelegate = cntlr
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
        completedCheck(button)
    }
    @IBAction func completedCheck(_ sender: NSButton) {
        cntlr.completedWasChecked(atIndex: mainTableView.clickedRow, withState: sender.tag)
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

    func setupPrefs() {
        let notificationName = Notification.Name(rawValue: "PrefsChanged")
        NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { (notification) in
            self.mainTableView.usesAlternatingRowBackgroundColors = self.cntlr.mainTableViewSetAlternatingRows()
        }
    }
    
    func reloadData() {
        mainTableView.reloadData()
    }
    func reloadSidebar() {
        sourceOutlineView.reloadData()
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
    
    func addToDoToGroup(toDoRowIndex: Int, group: Group) {
//        guard let moID = (mainTableView.view(atColumn: 1, row: toDoRowIndex, makeIfNecessary: false) as? ToDoCellView)?.managedObjectID else { return }
//        cntlr.assigneToDoToGroup(moID: moID, group: group)
    }
    
    func setToDoToDaily(toDoRowIndex: Int) {
        guard let theToDo = cntlr.getToDo(fromTableView: mainTableView) else { return }
        cntlr.setToDaily(toDo: theToDo, isDaily: !theToDo.daily)
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
}
