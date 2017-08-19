//
//  ViewController.swift
//  Todo
//
//  Created by Alec Saunders on 8/13/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa
import CoreData

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet var mainTableView: NSTableView!
    @IBOutlet var textAddToDo: NSTextField!
    @IBAction func btnAdd(_ sender: NSButton) {
        let txt = textAddToDo.stringValue
        cntlr.save(currentToDoTitle: txt)
        textAddToDo.stringValue = ""
        mainTableView.reloadData()
    }
    @IBAction func completedCheck(_ sender: NSButton) {
        cntlr.completedWasChecked(state: sender.state, btnIndex: sender.tag)
        mainTableView.reloadData()
    }
    
    fileprivate enum CellIdentifiers {
        static let col_complete = "col_complete"
        static let col_toDoText = "col_toDoText"
    }
    
    let registeredTypes:[String] = [NSGeneralPboard]
    let cntlr = MainController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainTableView.delegate = self
        mainTableView.dataSource = self
        mainTableView.usesAlternatingRowBackgroundColors = true
        mainTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        mainTableView.register(forDraggedTypes: registeredTypes)
        mainTableView.doubleAction = #selector(self.doubleClickMainTVCell)
        mainTableView.reloadData()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return cntlr.mainTableToDoArray.count
    }
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let theToDo = cntlr.mainTableToDoArray[row]
        
        var cellIdentifier: String = ""
        
        var cell: NSTableCellView? = nil
        
        if tableColumn == tableView.tableColumns[0] {
            cellIdentifier = CellIdentifiers.col_complete
            cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
            if let completedCheck = cell?.subviews[0] as? NSButton {
                completedCheck.tag = row
                completedCheck.state = theToDo.completed ? 1 : 0
            }
        } else if tableColumn == tableView.tableColumns[1] {
            cellIdentifier = CellIdentifiers.col_toDoText
            cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = theToDo.title
        }
        
        return cell!
    }
    
    func doubleClickMainTVCell(sender: AnyObject) {
        guard let tv = sender as? NSTableView else { return }
        print(cntlr.mainTableToDoArray[tv.selectedRow])
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return .every
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.declareTypes(registeredTypes, owner: self)
        pboard.setData(data, forType: NSGeneralPboard)
        return true
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        let dragData = info.draggingPasteboard().data(forType: NSGeneralPboard)!
        let rowIndexes: IndexSet? = NSKeyedUnarchiver.unarchiveObject(with: dragData) as? IndexSet
        guard let ri: IndexSet = rowIndexes else { return true }
        let dragOrigin = ri.first!
        let dragDest = row
        cntlr.reorderToDos(dragOrigin: dragOrigin, dragDest: dragDest)
        mainTableView.reloadData()
        return true
    }
    
    
    func pressToDoBtn() {
        if !textAddToDo.stringValue.isEmpty {
            //save(currentToDoTitle: textAddToDo.stringValue)
            clearTextAddToDo()
            mainTableView.reloadData()
        }
    }

    func clearTextAddToDo() {
        textAddToDo.stringValue = ""
        textAddToDo.becomeFirstResponder()
    }
}

