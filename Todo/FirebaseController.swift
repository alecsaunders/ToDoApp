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

class FirebaseController: MTVDel2, ModelAccessorDelegate {
    private var user: User
    private var ref: DatabaseReference!
    private var fbItem: DatabaseReference!
    private var fbGroup: DatabaseReference!
    var fbQuery: DatabaseQuery?
    var itemsAreComplete = false
    
    var fetchedToDos: [ToDo] = []
    var fetchedGroups: [Group] = []
    
    init(usr: User) {
        ref = Database.database().reference()
        user = usr
        fbItem = ref.child(usr.uid).child("item")
        fbGroup = ref.child(usr.uid).child("group")
        loadAllFromFirebase()
    }
    
    func loadAllFromFirebase() {
        loadItems()
        loadCategories()
    }
    
    func loadItems() {
        print("Load Items")
        let query = setFirebaseQuery()
        query.observe(.value) { (snapshot) in
            self.parseFirebaseResults(snapshot)
            self.deleteOutOfDateToDos()
            print("post reload tv notification")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadTableViewUINotify"), object: nil)
        }
    }
    
    func loadCategories() {
        print("Load Categories")
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
            NotificationCenter.default.post(name: Notification.Name(rawValue: "reloadSidebarUINotify"), object: nil)
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
    
    func updateMainView(withSidebarItem sbItem: SidebarItem) {
        itemsAreComplete = false
        if let sbFilterItem = sbItem as? SidebarFilterItem {
            switch sbFilterItem.sbFilter! {
            case .all:
                fbQuery = fbItem.queryOrdered(byChild: "createdDate")
            case .daily:
                fbQuery = fbItem.queryOrdered(byChild: "daily").queryEqual(toValue: true)
            case .completed:
                itemsAreComplete = true
                fbQuery = fbItem.queryOrdered(byChild: "completedDate")
            }
        }
        if let sbCatItem = sbItem as? SidebarCategoryItem {
            guard let group = sbCatItem.sbCategory else { return }
            fbQuery = fbItem.queryOrdered(byChild: "groupID").queryEqual(toValue: group.groupID)
        }
        loadItems()
    }
    
    func getNewItemKey() -> String {
        return fbItem.childByAutoId().key
    }
    
    func getNewCategoryKey() -> String {
        return fbGroup.childByAutoId().key
    }
    
    func saveItem(toDo: ToDo) {
        fbItem.child(toDo.id).setValue(toDo.getDictionary())
    }
    
    func saveCagegory(category cat: Group) {
        let groupDict: [String: String] = ["groupID": cat.groupID, "groupName": cat.groupName]
        fbGroup.child(cat.groupID).setValue(groupDict)
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
    
    func delete(category: Group) {
        fbGroup.child(category.groupID).removeValue(completionBlock: { (error, ref) in
            if let err = error {
                print(err.localizedDescription)
            } else {
                print("Deleted Group")
            }
        })
    }
    
    func deleteOutOfDateToDos() {
        for t in fetchedToDos {
            if shouldDelete(toDo: t) {
                delete(item: t)
            }
        }
    }
    
    func shouldDelete(toDo: ToDo) -> Bool {
        guard let completedDate = toDo.completedDate else { return false }
        let defaults = NSUserDefaultsController().defaults
        guard let retention = defaults.value(forKey: "completeRetention") as? Int else { return false }
        guard let retentionDateTime = Calendar.current.date(byAdding: .day, value: -retention, to: Date()) else { return false }
        
        if completedDate < retentionDateTime {
            return true
        } else {
            return false
        }
    }
    
    func update(item: ToDo, property prop: String, with newVal: Any?) {
        if let newValUnwrapped = newVal {
            switch prop {
            case "id", "title", "note":
                let newValTyped = newValUnwrapped as! String
                fbItem.child(item.id).child(prop).setValue(newValTyped)
            case "daily":
                let newValTyped = newValUnwrapped as! Bool
                fbItem.child(item.id).child(prop).setValue(newValTyped)
            case "createdDate":
                let newValTyped = (newValUnwrapped as! Date).timeIntervalSince1970
                fbItem.child(item.id).child(prop).setValue(newValTyped)
            case "completedDate":
                let newValTyped = (newValUnwrapped as! Date).timeIntervalSince1970
                // FIXME: - figure out the logic to set multiple values at once
                //                fbItem.child(item.id).setValuesForKeys(["isComplete": true, "completedDate": Double(newValTyped)])
                fbItem.child(item.id).child("isComplete").setValue(true)
                fbItem.child(item.id).child(prop).setValue(newValTyped)
            case "groupID":
                let newValTyped = newValUnwrapped as! String
                fbItem.child(item.id).child(prop).setValue(newValTyped)
            default:
                print("nothing to do")
            }
        } else {
            if prop == "completedDate" {
                fbItem.child(item.id).child("isComplete").setValue(false)
                fbItem.child(item.id).child(prop).removeValue()
            }
        }
    }
    
    func update(category: Group, forProperty prop: String, withNewVal val: String) {
        fbGroup.child(category.groupID).child(prop).setValue(val)
    }
    
    func getItem(fromUniqueID id: String) -> ToDo? {
        let filteredToDos = fetchedToDos.filter { $0.id == id }
        if filteredToDos.count == 0 {
            print("ERROR: No match found for id '\(id)'")
            return nil
        } else if filteredToDos.count == 1 {
            return filteredToDos[0]
        } else {
            print("ERROR: More than one ToDo was returned for id '\(id)'")
            return nil
        }
    }
    
    func getCategory(fromUniqueID id: String) -> Group? {
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

