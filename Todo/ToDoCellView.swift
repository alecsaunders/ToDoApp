//
//  ToDoCellView.swift
//  Todo
//
//  Created by Alec Saunders on 8/23/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

protocol ToDoCellViewDelegate: class {
    func changeText(newToDoTitle: String, atIndex: Int)
}

class ToDoCellView: NSTableCellView, NSTextFieldDelegate {
    weak var toDoCellViewDelegate: ToDoCellViewDelegate?
    var index: Int?
    @IBOutlet weak var toDoItemText: NSTextField!
    @IBAction func toDoItemTextAction(_ sender: NSTextField) {
        let newText = toDoItemText.stringValue
        if let toDoDel = toDoCellViewDelegate {
            guard let cellIndex = index else { return }
            toDoDel.changeText(newToDoTitle: newText, atIndex: cellIndex)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
}
