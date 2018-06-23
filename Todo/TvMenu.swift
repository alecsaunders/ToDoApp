//
//  tvMenu.swift
//  Todo
//
//  Created by Alec Saunders on 9/27/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

protocol TableViewMenuDelegate: class {
    func setMenuDailyState(sender: NSMenuItem)
}

class TvMenu: NSMenu {
    weak var tvMenuDelegate: TableViewMenuDelegate?
    @IBOutlet var menuDaily: NSMenuItem!

    override func awakeFromNib() {

    }
    
    override func update() {
        if let tvMenuDel = tvMenuDelegate {
            tvMenuDel.setMenuDailyState(sender: menuDaily)
        }
    }
    
}
