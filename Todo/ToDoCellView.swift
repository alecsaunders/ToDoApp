//
//  ToDoCellView.swift
//  Todo
//
//  Created by Alec Saunders on 8/23/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

protocol ToDoCellViewDelegate: class {
    func changeText(forToDo toDo: ToDo, withText text: String)
//    func changeText(newToDoTitle: String, moID: NSManagedObjectID)
}

class ToDoCellView: NSTableCellView, NSTextFieldDelegate {
    weak var toDoCellViewDelegate: ToDoCellViewDelegate?
    var cellToDo: ToDo?
    var managedObjectID: NSManagedObjectID?
    @IBOutlet weak var toDoItemText: NSTextField!
    @IBAction func toDoItemTextAction(_ sender: NSTextField) {
        guard let toDoDel = toDoCellViewDelegate else { return }
        guard let selfToDo = cellToDo else { return }
        toDoDel.changeText(forToDo: selfToDo, withText: toDoItemText.stringValue)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        toDoItemText.isEditable = true
    }
}
