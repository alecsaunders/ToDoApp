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
    
    var toDoEntityArray: [NSManagedObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mainTableView.delegate = self
        mainTableView.dataSource = self
        
        guard let appDelegate = NSApplication.shared().delegate as? AppDelegate else {
                return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "ToDo")
        do {
            toDoEntityArray = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        mainTableView.reloadData()
    }
    
    

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return toDoEntityArray.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = mainTableView.make(withIdentifier: "toDoCell", owner: self) as! NSTableCellView
        let theToDo = toDoEntityArray[row]
        cell.textField?.stringValue = theToDo.value(forKeyPath: "title") as! String
        
        return cell
    }
    
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
        let person = NSManagedObject(entity: entity, insertInto: managedContext)
        person.setValue(currentToDoItem, forKeyPath: "title")
        do {
            try managedContext.save()
            toDoEntityArray.append(person)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func clearTextAddToDo() {
        textAddToDo.stringValue = ""
        textAddToDo.becomeFirstResponder()
    }

}

