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
    func animate(hide: Bool)
}

class WindowController: NSWindowController, NSWindowDelegate {
    @IBOutlet var mainWindow: NSWindow!
    @IBOutlet weak var toDoCreateTextField: NSTextField!
    @IBAction func toDoTextFieldAction(_ sender: NSTextField) {
        windowControllerDelegate?.addToDo(toDoText: sender.stringValue)
        windowControllerDelegate?.clearToDoTextField(sender: sender)
    }
    weak var windowControllerDelegate: WindowControllerDelegate?
    var sidebarShouldHide: Bool = false

    override func windowWillLoad() {
        super.windowWillLoad()
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        if mainWindow.frame.width < 400 {
            sidebarShouldHide = false
        } else {
            sidebarShouldHide = true
        }
        
        mainWindow.titleVisibility = .hidden
        mainWindow.delegate = self
    }
    
    
    func windowDidResize(_ notification: Notification) {
        if sidebarShouldHide {
            if mainWindow.frame.width >= 400 {
                sidebarShouldHide = false
                windowControllerDelegate?.animate(hide: sidebarShouldHide)
            }
        } else {
            if mainWindow.frame.width < 400 {
                sidebarShouldHide = true
                windowControllerDelegate?.animate(hide: sidebarShouldHide)
            }
        }
    }
}
