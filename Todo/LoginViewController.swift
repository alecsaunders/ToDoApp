//
//  LoginViewController.swift
//  Todo
//
//  Created by Alec Saunders on 6/26/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Cocoa
import FirebaseAuth

class LoginViewController: NSViewController {
    var userIsLoggedIn: Bool = false
    @IBOutlet weak var btnContinue: NSButton!
    @IBOutlet weak var txtEmail: NSTextField!
    @IBOutlet weak var txtPassword1: NSSecureTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnSignIn(_ sender: NSButton) {
        print("btnSignIn")
        btnContinue.isEnabled = true
        userIsLoggedIn = true
    }
    @IBAction func btnCreateAccount(_ sender: NSButton) {
        let email = txtEmail.stringValue
        let password = txtPassword1.stringValue
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            print("Auth result: \(authResult)")
            print("Auth result: \(error)")
        }
        btnContinue.isEnabled = true
        userIsLoggedIn = true
    }
    
    @IBAction func btnContine(_ sender: NSButton) {
        if userIsLoggedIn {
            self.view.window?.close()
        }
    }
}
