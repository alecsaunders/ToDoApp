//
//  InfoViewController.swift
//  Todo
//
//  Created by Alec Saunders on 8/29/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa

class InfoViewController: NSViewController {
    var infoTitleString: String?
    @IBOutlet var infoTitle: NSTextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        infoTitle.stringValue = infoTitleString ?? "some label"
    }
    
}
