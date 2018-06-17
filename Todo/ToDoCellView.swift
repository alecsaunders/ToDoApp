//
//  ToDoCellView.swift
//  Todo
//
//  Created by Alec Saunders on 8/23/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

protocol ToDoCellViewDelegate: class {
//    func changeText(newToDoTitle: String, moID: NSManagedObjectID)
}

class ToDoCellView: NSTableCellView, NSTextFieldDelegate {
    weak var toDoCellViewDelegate: ToDoCellViewDelegate?
    var managedObjectID: NSManagedObjectID?
    @IBOutlet weak var toDoItemText: NSTextField!
    @IBAction func toDoItemTextAction(_ sender: NSTextField) {
        let newText = toDoItemText.stringValue
        if let toDoDel = toDoCellViewDelegate {
            guard let moID = managedObjectID else { return }
//            toDoDel.changeText(newToDoTitle: newText, moID: moID)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        toDoItemText.isEditable = true
//        
//        let font = NSFont(name: "Optima", size: 13)
//        toDoItemText.font = font
    }
}
