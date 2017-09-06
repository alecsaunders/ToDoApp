//
//  Group+CoreDataProperties.swift
//  Todo
//
//  Created by Alec Saunders on 9/4/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Foundation
import CoreData


extension Group {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Group> {
        return NSFetchRequest<Group>(entityName: "Group")
    }

    @NSManaged public var groupName: String?
    @NSManaged public var toDo: NSSet?

}

// MARK: Generated accessors for toDo
extension Group {

    @objc(addToDoObject:)
    @NSManaged public func addToToDo(_ value: ToDo)

    @objc(removeToDoObject:)
    @NSManaged public func removeFromToDo(_ value: ToDo)

    @objc(addToDo:)
    @NSManaged public func addToToDo(_ values: NSSet)

    @objc(removeToDo:)
    @NSManaged public func removeFromToDo(_ values: NSSet)

}
