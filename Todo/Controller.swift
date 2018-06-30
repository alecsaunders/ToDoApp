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

    func getItem(fromView view: NSView?) -> ToDo? {
        guard let itemCellView = view as? ToDoCellView else { return nil }
        return itemCellView.cellToDo
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

    
    func completedWasChecked(forItem item: ToDo?, withState state: Int) {
        guard var completedItem = item else { return }
        switch state {
        case 1:
            completedItem.completedDate = Date()
            completedItem.isComplete = true
        case 0:
            completedItem.completedDate = nil
            completedItem.isComplete = false
        default:
            break
        }
        updateForCompletion(item: completedItem, withCompletedDate: completedItem.completedDate)
    }
    

    
    //MARK: - Table View Menu Delegate Functions
    func setMenuDailyState(sender: NSMenuItem) {
        guard let clickedToDo = mainTableViewDelgate?.clickedToDo else { return }
        sender.state = getDailyState(withDailyBoolVal: clickedToDo.daily)
    }
    
    func getDailyState(withDailyBoolVal boolVal: Bool) -> NSControl.StateValue {
        if boolVal {
            return .on
        }
        return .off
    }
    
    func mainTableViewSetAlternatingRows() -> Bool {
        let userDefaults = NSUserDefaultsController().defaults
        let alternateBool = userDefaults.bool(forKey: "alternateRows")
        return alternateBool
    }
    
    func setupInfoSegue(dest: InfoViewController, withToDo todo: ToDo) {
        dest.infoToDo = todo
        dest.intoCreatedDateString = getString(fromDate: todo.createdDate, withFormat: "yyyy-MM-dd")
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
    
    // MARK: - Update To Do Items
    func setToDaily(toDo: ToDo, isDaily: Bool) {
        modelAccessorDel?.update(item: toDo, property: "daily", with: isDaily)
    }
    
    func updateForCompletion(item: ToDo, withCompletedDate complDate: Date?) {
        modelAccessorDel?.update(item: item, property: "completedDate", with: complDate)
    }
    
    func assignToDo(withID id: String, toGroup group: Group) {
        guard let toDoId = modelAccessorDel?.getItem(fromUniqueID: id) else { return }
        modelAccessorDel?.update(item: toDoId, property: "groupID", with: group.groupID)
    }

}
