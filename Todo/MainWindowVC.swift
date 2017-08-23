//
//  ViewController.swift
//  Todo
//
//  Created by Alec Saunders on 8/13/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa
import CoreData


class ViewController: NSViewController, MainTableViewDelgate, WindowControllerDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @IBOutlet var mainTableView: NSTableView!
    @IBOutlet var lblStatusBottom: NSTextField!
    @IBOutlet weak var sourceSidebar: NSScrollView!
    @IBOutlet weak var sourceOutlineView: NSOutlineView!
    @IBAction func btnAddItem(_ sender: NSButton) {
        if let windowConroller = self.view.window?.windowController as? WindowController {
            let txt = windowConroller.toDoCreateTextField.stringValue
            addToDoItemToMainTableView(toDoText: txt)
            windowConroller.toDoCreateTextField.stringValue = ""
        }
    }
    @IBAction func completedCheck(_ sender: NSButton) {
        cntlr.completedWasChecked(state: sender.state, btnIndex: sender.tag)
    }

    let cntlr = MainController()
    
    var outlineGroups = ["All", "Favorites"]
    
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
        
        sourceOutlineView.delegate = self
        sourceOutlineView.dataSource = self
        
    }
    
    func animate(hide: Bool) {
        sourceSidebar.animator().isHidden = hide
    }
    
    
    // MARK: - Main Table View Delegate Functions
    func doubleClick(sender: AnyObject) {
        cntlr.doubleClickMainTVCell(sender: sender)
    }
    
    func reloadData() {
        mainTableView.reloadData()
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
        print("update view contraints")
        super.updateViewConstraints()
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return outlineGroups.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return outlineGroups[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let view = outlineView.make(withIdentifier: "HeaderCell", owner: self) as! NSTableCellView
        if let textField = view.textField {
            textField.stringValue = item as! String
        }
        return view
    }
}
