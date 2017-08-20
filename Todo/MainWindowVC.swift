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
    @IBOutlet var mainTableView: NSTableView!
    @IBAction func btnAddItem(_ sender: NSButton) {
        if let windowConroller = self.view.window?.windowController as? WindowController {
            let txt = windowConroller.toDoTextField.stringValue
            addToDoItemToMainTableView(toDoText: txt)
            windowConroller.toDoTextField.stringValue = ""
        }
    }
    @IBAction func completedCheck(_ sender: NSButton) {
        cntlr.completedWasChecked(state: sender.state, btnIndex: sender.tag)
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
        mainTableView.delegate = cntlr
        mainTableView.dataSource = cntlr
        mainTableView.usesAlternatingRowBackgroundColors = true
        mainTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        mainTableView.register(forDraggedTypes: cntlr.registeredTypes)
        mainTableView.doubleAction = #selector(cntlr.doubleClickMainTVCell)
        mainTableView.reloadData()
    }
    
    // MARK: - Main Table View Delegate Functions
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
    
}
