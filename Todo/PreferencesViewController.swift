//
//  PreferencesViewController.swift
//  Todo
//
//  Created by Alec Saunders on 9/28/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

enum retentionEnum: Int {
    case immediatly = 0
    case one = 1
    case ten = 10
    case thirty = 30
}
class PreferencesViewController: NSViewController {

    @IBOutlet var retentionPopUp: NSPopUpButton!
    @IBAction func retentionPopUpAction(_ sender: NSPopUpButton) {
        let selectedIndex = sender.indexOfSelectedItem
        
        let userDefaults = NSUserDefaultsController().defaults
        
        switch selectedIndex {
        case 0:
            userDefaults.set(0, forKey: "completeRetention")
        case 1:
            userDefaults.set(1, forKey: "completeRetention")
        case 2:
            userDefaults.set(10, forKey: "completeRetention")
        case 3:
            userDefaults.set(30, forKey: "completeRetention")
        default:
            userDefaults.set(30, forKey: "completeRetention")
        }        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let userDefaults = NSUserDefaultsController().defaults
        guard let retentionSettingValue = userDefaults.value(forKey: "completeRetention") as? Int else { return }
        guard let popUpIndex = retentionEnum.init(rawValue: retentionSettingValue)?.hashValue else { return }
        retentionPopUp.selectItem(at: popUpIndex)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
