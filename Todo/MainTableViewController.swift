//
//  MainTableViewController.swift
//  Todo
//
//  Created by Alec Saunders on 4/13/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Foundation
import Cocoa
import CoreData

protocol MainTableViewDelgate: class {
    func reloadData()
    func reloadSidebar()
//    func addToDoToGroup(toDoRowIndex: Int, group: Group)
    func setToDoToDaily(toDoRowIndex: Int)
    func updateStatusBar(withText text: String)
    var clickedToDo: ToDo? { get }
}

protocol MTVDel2 {
    var fetchedToDos: [ToDo] { get set }
}

class MainTableViewController: NSObject, NSTableViewDelegate, NSTableViewDataSource, ToDoCellViewDelegate, NSFetchedResultsControllerDelegate {
    
    let registeredTypes = [NSPasteboard.PasteboardType.string]
    weak var mainTableViewDelgate: MainTableViewDelgate?
    var mtvdel2: MTVDel2?
    
    override init() {
        super.init()
    }
    
    func updateStatusBar(numOfItems: Int, sidebarGroup: Group?) {
        let statusBarText = "\(sidebarGroup != nil ? "\(sidebarGroup!) - " : "")\(numOfItems == 1  ? "\(numOfItems) item" : "\(numOfItems) items")"
        mainTableViewDelgate?.updateStatusBar(withText: statusBarText)
    }
    
    // MARK: - To Do Table View Delegate Methods
    func changeText(newToDoTitle: String) {
//        guard let toDoObj = getToDo(moID: moID) else { return }
//        toDoObj.setValue(newToDoTitle, forKey: "title")
//        dataController.saveMoc()
    }

    
    //MARK: - TableView Delegate Methods
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let mtv2 = mtvdel2 else { return 0 }
        updateStatusBar(numOfItems: mtv2.fetchedToDos.count, sidebarGroup: nil)
        return mtv2.fetchedToDos.count
    }
    
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let mtv2 = mtvdel2 else { return nil }
        let theToDo = mtv2.fetchedToDos[row]
        
        if tableColumn == tableView.tableColumns[0] {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "col_complete"), owner: nil) as? NSTableCellView else { return nil }
            if let completeBtn = cell.subviews[0] as? NSButton {
                if let _ = theToDo.completedDate {
                    completeBtn.state = NSControl.StateValue.on
                } else {
                    completeBtn.state = NSControl.StateValue.off
                }
                completeBtn.tag = row
            }
            return cell
        }
        if tableColumn == tableView.tableColumns[1] {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "col_toDoText"), owner: nil) as? ToDoCellView else { return nil }
            cell.cellToDo = theToDo
            cell.textField?.stringValue = cell.cellToDo!.title
            cell.toDoCellViewDelegate = self
            
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
}
