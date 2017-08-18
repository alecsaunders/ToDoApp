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
        pressToDoBtn()
    }
    @IBAction func completedCheck(_ sender: NSButton) {
        completedWasChecked(checkedBox: sender)
    }
    
    fileprivate enum CellIdentifiers {
        static let col_complete = "col_complete"
        static let col_toDoText = "col_toDoText"
    }
    
    var toDoEntityArray: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetchCDEntities()
        
        mainTableView.delegate = self
        mainTableView.dataSource = self
        mainTableView.reloadData()
    }
    
    func fetchCDEntities() {
        let appDelegate = NSApplication.shared().delegate as? AppDelegate
        let managedContext = appDelegate?.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ToDo")
        do {
            try toDoEntityArray = managedContext!.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return toDoEntityArray.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let theToDo = toDoEntityArray[row]
        var cellIdentifier: String = ""
        
        var cell: NSTableCellView? = nil
        
        if tableColumn == tableView.tableColumns[0] {
            cellIdentifier = CellIdentifiers.col_complete
            cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
            if let completedCheck = cell?.subviews[0] as? NSButton {
                completedCheck.tag = row
                completedCheck.state = 0 // remove this code, it's a hack
            }
        } else if tableColumn == tableView.tableColumns[1] {
            cellIdentifier = CellIdentifiers.col_toDoText
            cell = tableView.make(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
            cell?.textField?.stringValue = theToDo.value(forKeyPath: "title") as! String
        }
        
        return cell!
    }
    
    
    /////////////////
    // test stuff
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return nil
    }
    // end test stuff
    /////////////////
    
    
    func pressToDoBtn() {
        if !textAddToDo.stringValue.isEmpty {
            save(currentToDoItem: textAddToDo.stringValue)
            clearTextAddToDo()
            mainTableView.reloadData()
        }
    }

    func save(currentToDoItem: String) {
        guard let appDelegate = NSApplication.shared().delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "ToDo", in: managedContext)!
        let toDoEntityRecord = NSManagedObject(entity: entity, insertInto: managedContext)
        toDoEntityRecord.setValue(currentToDoItem, forKeyPath: "title")
        do {
            try managedContext.save()
            toDoEntityArray.append(toDoEntityRecord)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func clearTextAddToDo() {
        textAddToDo.stringValue = ""
        textAddToDo.becomeFirstResponder()
    }
    
    func completedWasChecked(checkedBox: NSButton) {
        switch checkedBox.state {
        case NSOnState:
            removeToDoEntityRecord(atIndex: checkedBox.tag)
        case NSOffState:
            break
        default:
            break
        }
    }
    
    
    func removeToDoEntityRecord(atIndex: Int) {
        let appDelegate = NSApplication.shared().delegate as? AppDelegate
        let managedContext = appDelegate?.persistentContainer.viewContext
        if let context = managedContext {
            context.delete(toDoEntityArray[atIndex])
            do {
                try context.save()
            } catch let error as NSError {
                print("Could not delete. \(error), \(error.userInfo)")
            }
        }
        fetchCDEntities()
        mainTableView.reloadData()
    }

}

