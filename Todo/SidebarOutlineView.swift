//
//  SidebarOutlineView.swift
//  Todo
//
//  Created by Alec Saunders on 9/28/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

class SidebarOutlineView: NSOutlineView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

    }
    
//    override func frameOfOutlineCell(atRow row: Int) -> NSRect {
//        return NSZeroRect
//    }
//
//    override func frameOfCell(atColumn column: Int, row: Int) -> NSRect {
//        let superframe = super.frameOfCell(atColumn: column, row: row)
//        return NSMakeRect(14, superframe.origin.y, self.bounds.size.width, superframe.size.height)
//    }
}
