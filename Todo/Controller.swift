//
//  Controller.swift
//  Todo
//
//  Created by Alec Saunders on 8/19/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa


class MainController: NSObject, InfoControllerDelegate, TableViewMenuDelegate, ToDoCellViewDelegate, GroupCellViewDelegate {
    weak var mainTableViewDelgate: MainTableViewDelgate?
    var modelAccessorDel: ModelAccessorDelegate?
    
    func getStatusLabel(withNumber num: Int, forGroup group: Group?) -> String {
        return "\(group != nil ? "\(group!.groupName) - " : "")\(num == 1  ? "\(num) item" : "\(num) items")"
    }

    func getToDo(fromTableView tableView: NSTableView, atIndex index: Int) -> ToDo? {
        guard let theToDo = (tableView.view(atColumn: 1, row: index, makeIfNecessary: false) as? ToDoCellView)?.cellToDo else { return nil }
        return theToDo
    }

    func saveNewToDo(withTitle title: String, withSidebarItem sbitem: SidebarItem?) {
        guard !title.isEmpty else { return }
        guard let modelAccDel = modelAccessorDel else { return }
        let newKey = modelAccDel.getNewItemKey()
        let newToDo = ToDo(id: newKey, title: title, note: "", daily: false, createdDate: Date(), isComplete: false, completedDate: nil, groupID: nil)
        modelAccDel.saveItem(toDo: newToDo)
    }
    
    func saveNewGroup(withName name: String) {
        guard let modelAccDel = modelAccessorDel else { return }
        let newKey = modelAccDel.getNewCategoryKey()
        let newGroup = Group(groupID: newKey, groupName: name)
        modelAccDel.saveCagegory(category: newGroup)
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
        modelAccessorDel?.update(item: toDo, property: "title", with: text)
    }

    func updateNote(forToDo toDo: ToDo, withNewNote note: String) {
        modelAccessorDel?.update(item: toDo, property: "note", with: note)
    }
    
    
    // MARK: - Update View

    func updateMainView(withSidebarItem sidebarItem: SidebarItem) {
        modelAccessorDel?.updateMainView(withSidebarItem: sidebarItem)
    }
    
    func assignToDo(withID id: String, toGroup group: Group) {
        guard let toDoId = modelAccessorDel?.getItem(fromUniqueID: id) else { return }
        modelAccessorDel?.update(item: toDoId, property: "groupID", with: group.groupID)
    }
    
    func setToDaily(toDo: ToDo, isDaily: Bool) {
        modelAccessorDel?.update(item: toDo, property: "daily", with: isDaily)
    }
    
    func completedWasChecked(inTableView tableView: NSTableView, atIndex index: Int, withState state: Int) {
        guard var completedToDo = getToDo(fromTableView: tableView, atIndex: index) else { return }
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
        updateForCompletion(item: completedToDo, withCompletedDate: completedToDo.completedDate)
    }
    
    func updateForCompletion(item: ToDo, withCompletedDate complDate: Date?) {
        modelAccessorDel?.update(item: item, property: "completedDate", with: complDate)
    }
    
    //MARK: - Table View Menu Delegate Functions
    func setMenuDailyState(sender: NSMenuItem) {
        guard let clickedToDo = mainTableViewDelgate?.clickedToDo else { return }
        sender.state = getDailyState(withDailyBoolVal: clickedToDo.daily)
    }
    
    func getDailyState(withDailyBoolVal boolVal: Bool) -> NSControl.StateValue {
        if boolVal {
            return .on
        } else {
            return .off
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
        guard let theGroup = modelAccessorDel?.getCategory(fromUniqueID: id) else { return }
        modelAccessorDel?.update(category: theGroup, forProperty: "groupName", withNewVal: title)
    }
    
    func deleteSidebarCategory(withCategoryItem item: SidebarCategoryItem) {
        guard let deletedGroup = item.sbCategory else { return }
        modelAccessorDel?.delete(category: deletedGroup)
    }

}
