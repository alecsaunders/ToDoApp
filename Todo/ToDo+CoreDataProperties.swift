//
//  ToDo+CoreDataProperties.swift
//  Todo
//
//  Created by Alec Saunders on 9/4/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Foundation
import CoreData


extension ToDo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDo> {
        return NSFetchRequest<ToDo>(entityName: "ToDo")
    }

    @NSManaged public var completed: Bool
    @NSManaged public var createdDate: NSDate?
    @NSManaged public var completedDate: NSDate?
    @NSManaged public var note: String?
    @NSManaged public var daily: Bool
    @NSManaged public var ordinalPosition: Int16
    @NSManaged public var title: String?
    @NSManaged public var group: Group?

}
