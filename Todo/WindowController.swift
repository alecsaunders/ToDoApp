//
//  WindowController.swift
//  Todo
//
//  Created by Alec Saunders on 8/19/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

protocol WindowControllerDelegate: class {
    func addToDo(toDoText: String)
    func clearToDoTextField(sender: NSTextField)
}

class WindowController: NSWindowController {
    @IBOutlet var toDoTextField: NSTextField!
    @IBAction func toDoTextFieldAction(_ sender: NSTextField) {
        windowControllerDelegate?.addToDo(toDoText: sender.stringValue)
        windowControllerDelegate?.clearToDoTextField(sender: sender)
    }
    weak var windowControllerDelegate: WindowControllerDelegate?

//    override func windowWillLoad() {
//        super.windowWillLoad()
//    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
        
    }

}
