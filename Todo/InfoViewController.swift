//
//  InfoViewController.swift
//  Todo
//
//  Created by Alec Saunders on 8/29/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

protocol InfoControllerDelegate: class {
    func updateNote(forToDo toDo: ToDo, withNewNote note: String)
}

class InfoViewController: NSViewController {
    var infoToDo: ToDo?
    var intoCreatedDateString: String?
    weak var infoControllerDelegate: InfoControllerDelegate?
    
    @IBOutlet var infoTitleTextField: NSTextField!
    @IBOutlet var infoCreatedDate: NSTextField!
    @IBOutlet var infoNote: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Data Settup
        infoTitleTextField.stringValue = infoToDo?.title ?? "title"
        infoNote.string = infoToDo?.note ?? ""
        infoCreatedDate.stringValue = intoCreatedDateString ?? "createDate"
        
        // View Settup
        infoNote.drawsBackground = false
        infoNote.backgroundColor = .clear
        infoNote.resignFirstResponder()
    }
    
    
    override func viewDidDisappear() {
        guard let itd = infoToDo else { return }
        infoControllerDelegate?.updateNote(forToDo: itd, withNewNote: infoNote.string)
    }
    
}
