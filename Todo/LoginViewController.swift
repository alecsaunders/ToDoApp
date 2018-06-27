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
        let email = txtEmail.stringValue
        let password = txtPassword1.stringValue
        
        guard !email.isEmpty else { return }
        guard !password.isEmpty else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if error == nil {
                print("logged in")
            } else {
                print("Error signing in: \(error!.localizedDescription)")
            }
            
        }
        
        btnContinue.isEnabled = true
        userIsLoggedIn = true
    }
    @IBAction func btnCreateAccount(_ sender: NSButton) {
        let email = txtEmail.stringValue
        let password = txtPassword1.stringValue
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if error == nil {
                if let user = authResult?.user {
                    let defaults = NSUserDefaultsController().defaults
                    defaults.setValue(user.uid, forKey: "firebase_uid")
                    defaults.setValue(user.email, forKey: "firebase_email")
                    self.userIsLoggedIn = true
                } else {
                    print("Could not downcast uid")
                }
            } else {
                print("Auth Error: \(error!.localizedDescription)")
            }
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
