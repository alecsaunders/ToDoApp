//
//  Controller.swift
//  Todo
//
//  Created by Alec Saunders on 8/19/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa


class MainController: NSObject, InfoControllerDelegate, TableViewMenuDelegate, FBControllerDelegate, ToDoCellViewDelegate, GroupCellViewDelegate {
    
    var firebaseController: FirebaseController!
    weak var mainTableViewDelgate: MainTableViewDelgate?
    
    override init() {
        firebaseController = FirebaseController()
        super.init()
        firebaseController.fbControlDel = self
    }

    func reloadUI() {
        mainTableViewDelgate?.reloadData()
    }
    
    func reloadSidebarUI() {
        mainTableViewDelgate?.reloadSidebar()

    }
    
    func getStatusLabel(withNumber num: Int, forGroup group: Group?) -> String {
        return "\(group != nil ? "\(group!) - " : "")\(num == 1  ? "\(num) item" : "\(num) items")"
    }

    func getToDo(fromTableView tableView: NSTableView) -> ToDo? {
        guard let theToDo = (tableView.view(atColumn: 1, row: tableView.clickedRow, makeIfNecessary: false) as? ToDoCellView)?.cellToDo else { return nil }
        return theToDo
    }

    func saveNewToDo(withTitle title: String, withSidebarItem sbitem: SidebarItem?) {
        guard !title.isEmpty else { return }
        let newKey = firebaseController.getNewToDoKey()
        let newToDo = ToDo(id: newKey, title: title, note: "", daily: false, createdDate: Date(), isComplete: false, completedDate: nil, groupID: nil)
        firebaseController.saveToDoToFirebase(toDo: newToDo)
    }
    
    func saveNewGroup(withName name: String) {
        let newKey = firebaseController.getNewGroupKey()
        let newGroup = Group(groupID: newKey, groupName: name)
        firebaseController.saveGroupToFirebase(group: newGroup)
    }
    
    func removeToDoEntityRecord(atIndex: Int) {
        print("removing to do record")
//        guard let fetchedObjs = toDoFetchedResultsController.fetchedObjects else { return }
//        guard let object = fetchedObjs[atIndex] as? NSManagedObject else { return }
//        dataController.managedObjectContext.delete(object)
//        dataController.saveMoc()
//        mainTableViewDelgate?.reloadData()
    }
    
    // MARK: - To Do Table View Delegate Methods
    func changeText(forToDo toDo: ToDo, withText text: String) {
        firebaseController.update(toDo: toDo, property: "title", with: text)
    }

    func updateNote(forToDo toDo: ToDo, withNewNote note: String) {
        firebaseController.update(toDo: toDo, property: "note", with: note)
    }
    
    
    // MARK: - Update View

    
    func assignToDo(withID id: String, toGroup group: Group) {
        guard let toDoId = firebaseController.getToDo(fromId: id) else { return }
        firebaseController.update(toDo: toDoId, property: "groupID", with: group.groupID)
    }
    
    func setToDaily(toDo: ToDo, isDaily: Bool) {
        firebaseController.update(toDo: toDo, property: "daily", with: isDaily)
    }
    
    func completedWasChecked(atIndex index: Int, withState state: Int) {
        var completedToDo = firebaseController.fetchedToDos[index]
        switch state {
        case 1:
            completedToDo.completedDate = Date()
            completedToDo.isComplete = true
        case 0:
            completedToDo.completedDate = nil
            completedToDo.isComplete = false
        default:
            break
        }
        firebaseController.update(toDo: completedToDo, property: "completedDate", with: completedToDo.completedDate)
    }
    
    //MARK: - Table View Menu Delegate Functions
    func setMenuDailyState(sender: NSMenuItem) {
        guard let mTvDel = mainTableViewDelgate else { return }
        guard let clickedToDo = mTvDel.clickedToDo else { return }
        
        if clickedToDo.daily {
            sender.state = .on
        } else {
            sender.state = .off
        }
    }
    
    func mainTableViewSetAlternatingRows() -> Bool {
        let userDefaults = NSUserDefaultsController().defaults
        let alternateBool = userDefaults.bool(forKey: "alternateRows")
        return alternateBool
    }
    
    func setupInfoSegue(dest: InfoViewController, withToDo todo: ToDo) {
        let clickedCreateDateString = getString(fromDate: todo.createdDate, withFormat: "yyyy-MM-dd")
        dest.infoToDo = todo
        dest.infoTitleString = todo.title
        dest.intoCreatedDateString = clickedCreateDateString
        dest.note = todo.note
    }
    
    func getString(fromDate date: Date, withFormat format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let clickedCreateDateString = dateFormatter.string(from: date)
        return clickedCreateDateString
    }
    
    func changeSidebarTitle(newTitle title: String, forGroupID id: String) {
        guard let theGroup = firebaseController.getGroup(fromId: id) else { return }
        firebaseController.update(group: theGroup, forProperty: "groupName", withNewVal: title)
    }
    
    func deleteSidebarCategory(withCategoryItem item: SidebarCategoryItem) {
        guard let deletedGroup = item.sbCategory else { return }
        firebaseController.delete(group: deletedGroup)
    }

}
