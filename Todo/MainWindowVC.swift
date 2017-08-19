//
//  ViewController.swift
//  Todo
//
//  Created by Alec Saunders on 8/13/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa
import CoreData


class ViewController: NSViewController, MainTableViewDelgate {
    @IBOutlet var mainTableView: NSTableView!
    @IBOutlet var textAddToDo: NSTextField!
    @IBAction func btnAdd(_ sender: NSButton) {
        let txt = textAddToDo.stringValue
        cntlr.save(currentToDoTitle: txt)
        textAddToDo.stringValue = ""
    }
    @IBAction func completedCheck(_ sender: NSButton) {
        cntlr.completedWasChecked(state: sender.state, btnIndex: sender.tag)
    }

    let cntlr = MainController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cntlr.mainTableViewDelgate = self
        mainTableView.delegate = cntlr
        mainTableView.dataSource = cntlr
        mainTableView.usesAlternatingRowBackgroundColors = true
        mainTableView.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        mainTableView.register(forDraggedTypes: cntlr.registeredTypes)
        mainTableView.doubleAction = #selector(cntlr.doubleClickMainTVCell)
        mainTableView.reloadData()
    }
    
    
    func reloadData() {
        mainTableView.reloadData()
    }
}
