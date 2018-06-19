//
//  FirebaseController.swift
//  Todo
//
//  Created by Alec Saunders on 6/16/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth

protocol FBControllerDelegate {
    func reloadUI()
}

class FirebaseController: MTVDel2 {
    private var ref: DatabaseReference!
    private var fbItem: DatabaseReference!
    var fbControlDel: FBControllerDelegate?
    var categoryDelegate: CategoryDelegate?
    var fetchedToDos: [ToDo]
    
    
    init() {
        fetchedToDos = []
        FirebaseApp.configure()
        Database.setLoggingEnabled(true)
        ref = Database.database().reference()
        fbItem = ref.child("item")
    }
    
    func loadDataFromFirebase() {
        fetchedToDos = []
        fbItem.observe(.childAdded) { (snapshot) in
            let decodedToDo = self.decodeFirebaseSnapshots(snapshot: snapshot)
            if let actualToDo = decodedToDo {
                self.fetchedToDos.append(actualToDo)
            }
            self.fbControlDel?.reloadUI()
        }
    }
    
    private func decodeFirebaseSnapshots(snapshot: DataSnapshot) -> ToDo? {
        var decodedToDo: ToDo?
        do {
            guard let fbChildToDoDict = snapshot.value as? [String: Any] else { return nil }
            let toDoData = try JSONSerialization.data(withJSONObject: fbChildToDoDict, options: [])
            decodedToDo = try JSONDecoder().decode(ToDo.self, from: toDoData)
        } catch {
            print("error decoding \(error)")
        }
        return decodedToDo
    }
    
    func getNewKey() -> String {
        return ref.child("item").childByAutoId().key
    }
    
    func saveToDoToFirebase(toDo: ToDo) {
        fbItem.child(toDo.id).setValue(toDo.getDictionary())
        loadDataFromFirebase()
    }
    
    func delete(item: ToDo) {
        fbItem.child(item.id).removeValue(completionBlock: { (error, ref) in
            if let err = error {
                print(err.localizedDescription)
            } else {
                print("Deleted item")
            }
        })
    }
    
    func update(toDo: ToDo, property prop: String, with newVal: Any?) {
        if let newValUnwrapped = newVal {
            switch prop {
            case "id", "title", "note":
                let newValTyped = newValUnwrapped as! String
                fbItem.child(toDo.id).child(prop).setValue(newValTyped)
            case "daily":
                let newValTyped = newValUnwrapped as! Bool
                fbItem.child(toDo.id).child(prop).setValue(newValTyped)
            case "createdDate", "completedDate":
                print("switch \(prop)")
                let newValTyped = (newValUnwrapped as! Date).timeIntervalSince1970
                fbItem.child(toDo.id).child(prop).setValue(newValTyped)
            default:
                print("nothing to do")
            }
        } else {
            if prop == "completedDate" {
                fbItem.child(toDo.id).child(prop).removeValue()
            }
        }
        loadDataFromFirebase()
    }
}

