//
//  FirebaseAuthController.swift
//  Todo
//
//  Created by Alec Saunders on 6/28/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseAuth

class FirebaseAuthController {
    var user: User?
    
    init() {
        FirebaseApp.configure()
    }
    
    func setUser(with object: Any?) {
        if let usr = object as? User {
            user = usr
        }
    }
    
    func getCurrentUser() -> User? {
        return nil
    }
    
    func isUserValidated() -> Bool {
        if let curUser = Auth.auth().currentUser {
            user = curUser
            return true
        } else {
            print("firebase auth cntl, could not get user")
            return false
        }
    }
    
}
