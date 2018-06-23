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

class FirebaseController: MTVDel2, CategoryDelegate {
    private var ref: DatabaseReference!
    private var fbItem: DatabaseReference!
    var fbQuery: DatabaseQuery?
    var fbControlDel: FBControllerDelegate?
    var fetchedToDos: [ToDo]
    var itemsAreComplete = false
    
    init() {
        fetchedToDos = []
        FirebaseApp.configure()
        Database.setLoggingEnabled(true)
        ref = Database.database().reference()
        fbItem = ref.child("item")
    }
    
    func loadDataFromFirebase() {
        let query = setFirebaseQuery()
        query.observe(.value) { (snapshot) in
            self.parseFirebaseResults(snapshot)
            self.fbControlDel?.reloadUI()
        }
    }
    
    func setFirebaseQuery() -> DatabaseQuery {
        guard let query = fbQuery else { return fbItem.queryOrdered(byChild: "createdDate") }
        return query
    }
    
    func parseFirebaseResults(_ snapshot: (DataSnapshot)) {
        self.fetchedToDos = []
        for child in snapshot.children.allObjects as! [DataSnapshot] {
            guard let fbChildToDoDict = child.value as? [String: Any] else { return }
            guard let decToDo = decodeFirebaseDictionary(fbChildToDoDict) else { return }
            fetchedToDos.append(decToDo)
        }
    }
    
    func decodeFirebaseDictionary(_ dict: [String : Any]) -> ToDo? {
        do {
            let toDoData = try JSONSerialization.data(withJSONObject: dict, options: [])
            let decodedToDo = try JSONDecoder().decode(ToDo.self, from: toDoData)
            if decodedToDo.isComplete == self.itemsAreComplete {
                return decodedToDo
            }
        } catch {
            print("Error decoding ToDo: \(error)")
        }
        return nil
    }
    
    func updateMainView(with sidebarSelection: SidebarItem) {
        itemsAreComplete = false
        if let sbFilterItem = sidebarSelection as? SidebarFilterItem {
            switch sbFilterItem.sbFilter! {
            case .all:
                fbQuery = fbItem.queryOrdered(byChild: "createdDate")
            case .daily:
                fbQuery = fbItem.queryOrdered(byChild: "daily").queryEqual(toValue: true)
            case .completed:
                itemsAreComplete = true
                fbQuery = fbItem.queryOrdered(byChild: "isComplete").queryEqual(toValue: true)
            }
        }
        loadDataFromFirebase()
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
            case "createdDate":
                let newValTyped = (newValUnwrapped as! Date).timeIntervalSince1970
                fbItem.child(toDo.id).child(prop).setValue(newValTyped)
            case "completedDate":
                let newValTyped = (newValUnwrapped as! Date).timeIntervalSince1970
                // FIXME: - figure out the logic to set multiple values at once
//                fbItem.child(toDo.id).setValuesForKeys(["isComplete": true, "completedDate": Double(newValTyped)])
                fbItem.child(toDo.id).child("isComplete").setValue(true)
                fbItem.child(toDo.id).child(prop).setValue(newValTyped)
            case "group":
                // FIXME: - This is not yet tested
                print("This is not yet tested")
                let newValTyped = newValUnwrapped as! String
                fbItem.child(toDo.id).child(prop).setValue(newValTyped)
            default:
                print("nothing to do")
            }
        } else {
            if prop == "completedDate" {
                fbItem.child(toDo.id).child("isComplete").setValue(false)
                fbItem.child(toDo.id).child(prop).removeValue()
            }
        }
    }
}

