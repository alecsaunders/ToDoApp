//
//  GroupCellView.swift
//  Todo
//
//  Created by Alec Saunders on 8/31/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

class GroupCellView: NSTableCellView {

    var groupID: NSManagedObjectID?
    @IBOutlet var txtGroup: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
}
