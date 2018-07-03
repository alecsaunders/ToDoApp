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
    
    func viewForTableViewColumn(completedCheckboxColumnCell view: NSView?, atRow row: Int, withItem item: ToDo) -> NSView? {
        guard let cellChk = view as? NSTableCellView else { return nil }
        guard let completeBtn = cellChk.subviews[0] as? NSButton else { return nil }
        completeBtn.tag = row
        completeBtn.state = item.isComplete ? .on : .off
        return cellChk
    }
    
    func viewForTableViewColumn(itemColumnCell view: NSView?, atRow row: Int, withItem item: ToDo) -> NSView? {
        guard let cellItm = view as? ToDoCellView else { return nil }
        cellItm.cellToDo = item
        cellItm.textField?.stringValue = cellItm.cellToDo!.title
        cellItm.toDoCellViewDelegate = self
        return cellItm
    }
    
    func getStatusLabel(withNumber num: Int, forGroup group: Group?) -> String {
        return "\(group != nil ? "\(group!.groupName) - " : "")\(num == 1  ? "\(num) item" : "\(num) items")"
    }

    func getItem(fromView view: NSView?) -> ToDo? {
        guard let itemCellView = view as? ToDoCellView else { return nil }
        return itemCellView.cellToDo
    }
    
    func mapGroupsToSidebarCategories(groupList list: [Group]) -> [SidebarCategoryItem] {
        let sidebarCategories = list.map { (g) -> SidebarCategoryItem in
            let newSbCatItem = SidebarCategoryItem(withTitle: g.groupName)
            newSbCatItem.sbCategory = g
            return newSbCatItem
        }
        return sidebarCategories
    }

    func saveNewToDo(withTitle title: String, withSidebarItem sbitem: SidebarItem?) {
        guard !title.isEmpty else { return }
        guard let newKey = modelAccessorDel?.getNewItemKey() else { return }
        let newToDo = ToDo(id: newKey, title: title, note: "", daily: false, createdDate: Date(), isComplete: false, completedDate: nil, groupID: nil)
        modelAccessorDel?.saveItem(toDo: newToDo)
    }
    
    func saveNewGroup(withName name: String) {
        guard let modelAccDel = modelAccessorDel else { return }
        let newKey = modelAccDel.getNewCategoryKey()
        let newGroup = Group(groupID: newKey, groupName: name)
        modelAccDel.saveCagegory(category: newGroup)
    }

    // MARK: - Update View
    func updateMainView(withSidebarItem sidebarItem: SidebarItem) {
        modelAccessorDel?.updateMainView(withSidebarItem: sidebarItem)
    }
    
    func completedWasChecked(forItem item: ToDo, withState state: Int) {
        updateCompletedDate(forItem: toggleCompletion(forItem: item, withState: state))
    }
    
    func changeState(ofButton button: NSButton) -> NSControl.StateValue {
        switch button.state {
        case .on:
            return .off
        case .off:
            return .on
        default:
            return .off
        }
    }
    
    func toggleCompletion(forItem: ToDo, withState state: Int) -> ToDo {
        var item = forItem
        switch state {
        case 1:
            item.completedDate = Date()
            item.isComplete = true
        case 0:
            item.completedDate = nil
            item.isComplete = false
        default:
            break
        }
        return item
    }
    
    func getFetchedItems(fromNotificationObject obj: Any?) -> [ToDo] {
        guard let noti_fetchedItems = obj as? [ToDo] else { return [] }
        return noti_fetchedItems
    }
    
    func getFetchedCategories(fromNotificationObject obj: Any?) -> [Group] {
        guard let noti_fetchedCategories = obj as? [Group] else { return [] }
        return noti_fetchedCategories
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
    func changeText(forToDo toDo: ToDo, withText text: String) { // ToDoCellViewDelegate method
        modelAccessorDel?.update(item: toDo, property: "title", with: text)
    }
    
    func updateNote(forToDo toDo: ToDo, withNewNote note: String) {  // InfoControllerDelegate method
        modelAccessorDel?.update(item: toDo, property: "note", with: note)
    }
    
    func setToDaily(toDo: ToDo, isDaily: Bool) {
        modelAccessorDel?.update(item: toDo, property: "daily", with: isDaily)
    }
    
    func assignToDo(withID id: String, toGroup group: Group) {
        guard let toDoId = modelAccessorDel?.getItem(fromUniqueID: id) else { return }
        modelAccessorDel?.update(item: toDoId, property: "groupID", with: group.groupID)
    }
    func updateCompletedDate(forItem item: ToDo) {
        modelAccessorDel?.update(item: item, property: "completedDate", with: item.completedDate)
    }
}
