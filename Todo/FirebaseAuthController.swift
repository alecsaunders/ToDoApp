//
//  FirebaseAuthController.swift
//  Todo
//
//  Created by Alec Saunders on 6/28/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Foundation
import FirebaseAuth

class FirebaseAuthController {
    var user: User?
    var isEmailVerified = false
    
    init() {
        print("init firebase auth controller")
    }
    
    func getCurrentUser() -> User? {
        return nil
    }
    
    func isUserValidated() -> Bool {
        print("fb auth cntl: isUserValidated")
        if let curUser = Auth.auth().currentUser {
            print(curUser.uid)
            if curUser.isEmailVerified {
                user = curUser
                return true
            } else {
                print("email is not verified")
                return false
            }
        } else {
            print("firebase auth cntl, could not get user")
            return false
        }
    }
    
}
