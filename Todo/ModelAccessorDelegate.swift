//
//  ModelAccessorDelegate.swift
//  Todo
//
//  Created by Alec Saunders on 6/29/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Foundation

protocol ModelAccessorDelegate {
    func saveItem(toDo: ToDo)
    func saveCagegory(category cat: Group)
    func update(item: ToDo, property prop: String, with newVal: Any?)
    func update(group: Group, forProperty prop: String, withNewVal val: String)
    func delete(item: ToDo)
    func delete(category: Group)
    func loadItems()
    func loadCategories()
    func getNewItemKey()
    func getNewCategoryKey()
    func getItem(fromUniqueID id: String)
    func getCategory(fromUniqueID id: String)
}
