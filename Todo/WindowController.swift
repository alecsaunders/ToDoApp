//
//  WindowController.swift
//  Todo
//
//  Created by Alec Saunders on 8/19/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    @IBOutlet var toDoTextField: NSTextField!

//    override func windowWillLoad() {
//        super.windowWillLoad()
//    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.titleVisibility = .hidden
    }

}
