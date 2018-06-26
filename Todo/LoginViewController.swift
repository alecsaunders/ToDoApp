//
//  LoginViewController.swift
//  Todo
//
//  Created by Alec Saunders on 6/26/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Cocoa

class LoginViewController: NSViewController {
    var userIsLoggedIn: Bool = false
    @IBOutlet weak var btnContinue: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnSignIn(_ sender: NSButton) {
        print("btnSignIn")
        btnContinue.isEnabled = true
        userIsLoggedIn = true
    }
    @IBAction func btnCreateAccount(_ sender: NSButton) {
        print("btnCreateAccount")
        btnContinue.isEnabled = true
        userIsLoggedIn = true
    }
    
    @IBAction func btnContine(_ sender: NSButton) {
        if userIsLoggedIn {
            self.view.window?.close()
        }
    }
}
