//
//  DataController.swift
//  Todo
//
//  Created by Alec Saunders on 9/4/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import Cocoa
import CoreData

class DataController: NSObject {
    
    var managedObjectContext: NSManagedObjectContext
    
    override init() {
        let appDel = NSApplication.shared.delegate as! AppDelegate
        managedObjectContext = appDel.persistentContainer.viewContext
    }
}
