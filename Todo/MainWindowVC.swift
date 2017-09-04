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
    let registeredTypes:[String] = [NSGeneralPboard]
    @IBOutlet var mainTableView: NSTableView!
    @IBOutlet var lblStatusBottom: NSTextField!
    @IBOutlet weak var sourceSidebar: NSScrollView!
    @IBOutlet var sidebarView: NSView!
    @IBOutlet weak var sourceOutlineView: NSOutlineView!
    @IBAction func btnAddItem(_ sender: NSButton) {
        if let windowConroller = self.view.window?.windowController as? WindowController {
            let txt = windowConroller.toDoCreateTextField.stringValue
            addToDoItemToMainTableView(toDoText: txt)
            windowConroller.toDoCreateTextField.stringValue = ""
        }
    }
    @IBAction func btnAddGroup(_ sender: NSButton) {
        cntlr.addSidebarGroup(groupName: "New Group")
        sourceOutlineView.reloadData()
        sourceOutlineView?.expandItem(nil, expandChildren: true)
    }
    @IBAction func completedCheck(_ sender: NSButton) {
        cntlr.completedWasChecked(state: sender.state, btnIndex: sender.tag)
    }
    @IBAction func markComplete(_ sender: NSMenuItem) {
        cntlr.completedWasChecked(state: 1, btnIndex: mainTableView.clickedRow)
    }
    @IBAction func menuGetInfo(_ sender: NSMenuItem) {
        if mainTableView.clickedRow >= 0 {
            performSegue(withIdentifier: "infoSegue", sender: self)
        }
    }
    @IBAction func sidebarMenuDelete(_ sender: NSMenuItem) {
        guard let item = sourceOutlineView.item(atRow: sourceOutlineView.clickedRow) as? Group else { return }
        cntlr.deleteSidebarGroup(group: item)
        sourceOutlineView.reloadData()
        sourceOutlineView?.expandItem(nil, expandChildren: true)
    }

    let cntlr = MainController()
    
    override func viewWillAppear() {
        if let windowConroller = self.view.window?.windowController as? WindowController {
            windowConroller.windowControllerDelegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cntlr.mainTableViewDelgate = self
        lblStatusBottom.textColor = NSColor.darkGray
        updateStatusBar(numOfItems: cntlr.mainTableToDoArray.count)
        mainTableView.delegate = cntlr
        mainTableView.dataSource = cntlr
        mainTableView.usesAlternatingRowBackgroundColors = true
        mainTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        mainTableView.register(forDraggedTypes: cntlr.registeredTypes)
        mainTableView.doubleAction = #selector(self.doubleClick)
        mainTableView.reloadData()
        
        sourceOutlineView.delegate = cntlr
        sourceOutlineView.dataSource = cntlr
        sourceOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        sourceOutlineView.register(forDraggedTypes: self.registeredTypes)
        sourceOutlineView?.expandItem(nil, expandChildren: true)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let dest = segue.destinationController as? InfoViewController else { return }
        let theClickedToDo = cntlr.mainTableToDoArray[mainTableView.clickedRow]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let clickedCreateDate = theClickedToDo.createdDate
        let clickedCreateDateString = dateFormatter.string(from: clickedCreateDate)
        dest.infoTitleString = theClickedToDo.title
        dest.intoCreatedDateString = clickedCreateDateString
        dest.note = theClickedToDo.note
        dest.managedContextId = theClickedToDo.managedContextID
        dest.infoControllerDelegate = cntlr
    }
    
    
    func animate(hide: Bool) {
        sourceSidebar.animator().isHidden = hide
        sidebarView.animator().isHidden = hide
    }
    
    // MARK: - Main Table View Delegate Functions
    func doubleClick(sender: AnyObject) {
        if mainTableView.clickedRow >= 0 {
            performSegue(withIdentifier: "infoSegue", sender: self)
        }
    }
    
    func reloadData(sidebarGroup: String) {
        cntlr.updateCurrentSelectionToDoArray(group: sidebarGroup)
        mainTableView.reloadData()
    }
    
    func reloadSidebar() {
        sourceOutlineView.reloadData()
        sourceOutlineView?.expandItem(nil, expandChildren: true)
    }
    
    // MARK: - Window Controller Delegate
    func addToDo(toDoText: String) {
        addToDoItemToMainTableView(toDoText: toDoText)
    }
    func clearToDoTextField(sender: NSTextField) {
        sender.stringValue = ""
    }
    
    // MARK: - Controller functions
    func addToDoItemToMainTableView(toDoText: String) {
        cntlr.save(currentToDoTitle: toDoText)
    }
    
    func updateStatusBar(numOfItems: Int) {
        lblStatusBottom.stringValue = "\(numOfItems) items"
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
    }
}
