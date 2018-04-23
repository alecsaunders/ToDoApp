//
//  FormatMenu.swift
//  Todo
//
//  Created by Alec Saunders on 4/23/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Cocoa

class FormatMenu: NSMenu {
    let userDefaults = NSUserDefaultsController().defaults
    
    @IBOutlet var menuAlternateRows: NSMenuItem!
    @IBAction func menuAlternateRows(_ sender: NSMenuItem) {
        let alternate = userDefaults.bool(forKey: "alternateRows")
        if alternate {
            userDefaults.set(false, forKey: "alternateRows")
            menuAlternateRows.state = .off
        } else {
            userDefaults.set(true, forKey: "alternateRows")
            menuAlternateRows.state = .on
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "PrefsChanged"), object: nil)
    }
    
    override func awakeFromNib() {
        let alternate = userDefaults.bool(forKey: "alternateRows")
        if alternate {
            menuAlternateRows.state = .on
        } else {
            menuAlternateRows.state = .off
        }
    }
}
