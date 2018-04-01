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
    
//    override func makeView(withIdentifier identifier: NSUserInterfaceItemIdentifier, owner: Any?) -> NSView? {
////        let hideShowButtonKey = NSOutlineView.showHideButtonIdentifier
//
//
//        return nil
//    }
    
//    override func frameOfOutlineCell(atRow row: Int) -> NSRect {
//        return NSZeroRect
//    }

    override func frameOfCell(atColumn column: Int, row: Int) -> NSRect {
        let superframe = super.frameOfCell(atColumn: column, row: row)
        
        if let _ = super.item(atRow: row) as? SidebarSection<String> {
            return NSMakeRect(7, superframe.origin.y, self.bounds.size.width, superframe.size.height)
        }
        if let _ = super.item(atRow: row) as? SidebarSection<Group> {
            return NSMakeRect(7, superframe.origin.y, self.bounds.size.width, superframe.size.height)
        }
        
        return NSMakeRect(21, superframe.origin.y, self.bounds.size.width, superframe.size.height)
    }
}
