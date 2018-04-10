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
    let registeredTypes:[String] = [NSPasteboard.Name.generalPboard.rawValue]
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
            cntlr.save(addedToDoTitle: txt)
            windowConroller.toDoCreateTextField.stringValue = ""
        }
    }
    @IBAction func btnAddGroup(_ sender: NSButton) {
        cntlr.addSidebarGroup(groupName: "New Group")
    }
    @IBAction func completedCheck(_ sender: NSButton) {
        cntlr.completedWasChecked(state: sender.state.rawValue, btnIndex: sender.tag)
    }
    @IBOutlet var tvMenu: TvMenu!
    @IBAction func markComplete(_ sender: NSMenuItem) {
        cntlr.completedWasChecked(state: 1, btnIndex: mainTableView.clickedRow)
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
        guard let item = sourceOutlineView.item(atRow: sourceOutlineView.clickedRow) as? Group else { return }
        cntlr.deleteSidebarGroup(group: item)
        sourceOutlineView.reloadData()
        sourceOutlineView?.expandItem(nil, expandChildren: true)
    }

    let cntlr = MainController()
    let outlineCntlr = OutlineViewController()
    
    override func viewWillAppear() {
        if let windowConroller = self.view.window?.windowController as? WindowController {
            windowConroller.windowControllerDelegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cntlr.mainTableViewDelgate = self
        lblStatusBottom.textColor = NSColor.darkGray
        mainTableView.delegate = cntlr
        mainTableView.dataSource = cntlr
        mainTableView.usesAlternatingRowBackgroundColors = true
        mainTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        mainTableView.registerForDraggedTypes(cntlr.registeredTypes)
        mainTableView.doubleAction = #selector(self.doubleClick)
        mainTableView.reloadData()
        
        sourceOutlineView.delegate = outlineCntlr
        sourceOutlineView.dataSource = outlineCntlr
        sourceOutlineView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: true)
        sourceOutlineView.registerForDraggedTypes([.string])
        sourceOutlineView?.expandItem(nil, expandChildren: true)
        
        tvMenu.tvMenuDelegate = cntlr
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
    
    
    func animate(hide: Bool) {
        sourceSidebar.animator().isHidden = hide
        sidebarView.animator().isHidden = hide
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
        mainTableView.reloadData()
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
        cntlr.save(addedToDoTitle: toDoText)
    }
    
    func updateStatusBar(numOfItems: Int, sidebarGroup: String?) {
        lblStatusBottom.stringValue = "\(sidebarGroup != nil ? "\(sidebarGroup!) - " : "")\(numOfItems) items"
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
    }
}
