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
    func reloadSidebarUI()
}

class FirebaseController: MTVDel2 {
    private var ref: DatabaseReference!
    private var fbItem: DatabaseReference!
    private var fbGroup: DatabaseReference!
    var fbQuery: DatabaseQuery?
    var fbControlDel: FBControllerDelegate?
    var itemsAreComplete = false
    
    var fetchedToDos: [ToDo] = []
    var fetchedGroups: [Group] = []
    
    init() {
        FirebaseApp.configure()
        Database.setLoggingEnabled(true)
        ref = Database.database().reference()
        fbItem = ref.child("item")
        fbGroup = ref.child("group")
    }
    
    func loadAllFromFirebase() {
        loadDataFromFirebase()
        loadGroupsFromFirebase()
    }
    
    func loadDataFromFirebase() {
        let query = setFirebaseQuery()
        query.observe(.value) { (snapshot) in
            self.parseFirebaseResults(snapshot)
            self.fbControlDel?.reloadUI()
        }
    }
    
    func loadGroupsFromFirebase() {
        fbGroup.observe(.value) { (snapshot) in
            self.fetchedGroups = []
            for child in self.getAllChildren(fromSnapshot: snapshot) {
                guard let fbGroupDict = child.value as? [String: String] else { continue }
                do {
                    let groupData = try JSONSerialization.data(withJSONObject: fbGroupDict, options: [])
                    let decodedGroup = try JSONDecoder().decode(Group.self, from: groupData)
                    self.fetchedGroups.append(decodedGroup)
                } catch {
                    print("Error decoding group: \(error)")
                }
            }
            self.fbControlDel?.reloadSidebarUI()
        }
    }
    
    func setFirebaseQuery() -> DatabaseQuery {
        guard let query = fbQuery else { return fbItem.queryOrdered(byChild: "createdDate") }
        return query
    }
    
    func parseFirebaseResults(_ snapshot: (DataSnapshot)) {
        self.fetchedToDos = []
        for child in getAllChildren(fromSnapshot: snapshot) {
            guard let val = child.value else { continue }
            guard let fbChildToDoDict = val as? [String: Any] else { continue }
            guard let decToDo = decodeFirebaseDictionary(fbChildToDoDict) else { continue }
            fetchedToDos.append(decToDo)
        }
    }
    
    func getAllChildren(fromSnapshot snapshot: (DataSnapshot)) -> [DataSnapshot] {
        guard let allChildren = snapshot.children.allObjects as? [DataSnapshot] else { return [] }
        return allChildren
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
    
    func getNewToDoKey() -> String {
        return fbItem.childByAutoId().key
    }
    func getNewGroupKey() -> String {
        return fbGroup.childByAutoId().key
    }
    
    func saveToDoToFirebase(toDo: ToDo) {
        fbItem.child(toDo.id).setValue(toDo.getDictionary())
    }
    
    func saveGroupToFirebase(group: Group) {
        let groupDict: [String: String] = ["groupID": group.groupID, "groupName": group.groupName]
        fbGroup.child(group.groupID).setValue(groupDict)
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
    
    func update(group: Group, forProperty prop: String, withNewVal val: String) {
        fbGroup.child(group.groupID).child(prop).setValue(val)
    }
    
    func getGroup(fromId id: String) -> Group? {
        let filteredGroups = fetchedGroups.filter { $0.groupID == id }
        if filteredGroups.count == 0 {
            print("ERROR: No match found for id '\(id)'")
            return nil
        } else if filteredGroups.count == 1 {
            return filteredGroups[0]
        } else {
            print("ERROR: More than one group was returned for id '\(id)'")
            return nil
        }
    }
}

