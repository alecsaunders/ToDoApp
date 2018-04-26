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
    var persistentContainer: NSPersistentContainer
    var managedObjectContext: NSManagedObjectContext
    
    override init() {
        let appDel = NSApplication.shared.delegate as! AppDelegate
        persistentContainer = appDel.persistentContainer
        managedObjectContext = persistentContainer.viewContext
    }
    
    func saveMoc() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                print("failed to save new to do")
            }
        } else {
            print("Managed Object Context NOT hasChanges")
        }
    }
}
