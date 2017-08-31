//
//  InfoViewController.swift
//  Todo
//
//  Created by Alec Saunders on 8/29/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

protocol InfoControllerDelegate: class {
    func updateNote(newNote: String, moID: NSManagedObjectID)
}

class InfoViewController: NSViewController, NSTextFieldDelegate {
    var managedContextId: NSManagedObjectID?
    var infoTitleString: String?
    var intoCreatedDateString: String?
    var note: String?
    weak var infoControllerDelegate: InfoControllerDelegate?
    
    @IBOutlet var infoTitleTextField: NSTextField!
    @IBOutlet var infoCreatedDate: NSTextField!
    @IBOutlet weak var infoNote: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        infoTitleTextField.stringValue = infoTitleString ?? "title"
        infoCreatedDate.stringValue = intoCreatedDateString ?? "createDate"
        infoNote.delegate = self
        infoNote.stringValue = note ?? ""
        infoNote.focusRingType = NSFocusRingType.none
    }
    
    
    override func viewDidDisappear() {
        guard let moID = managedContextId else { return }
        infoControllerDelegate?.updateNote(newNote: infoNote.stringValue, moID: moID)
    }
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let event = NSApplication.shared().currentEvent
        if event?.type == NSEventType.keyDown && event?.keyCode == 36 {
            infoNote.stringValue = infoNote.stringValue.appending("\n")
            return false
        }
        return true
    }
    
}
