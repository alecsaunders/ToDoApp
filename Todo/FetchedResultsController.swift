//
//  FetchedResultsController.swift
//  Todo
//
//  Created by Alec Saunders on 4/8/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Foundation
import Cocoa
import CoreData


class FetchedResultsController<ResultType: NSFetchRequestResult>: NSFetchedResultsController<NSFetchRequestResult> {
    let dataController = DataController()
    let moc: NSManagedObjectContext
    
    override init() {
        moc = dataController.managedObjectContext
        super.init()
    }
    
    override func object(at indexPath: IndexPath) -> NSFetchRequestResult {
        return super.object(at: indexPath)
    }
    
    override func indexPath(forObject object: NSFetchRequestResult) -> IndexPath? {
        return super.indexPath(forObject: object)
    }
    
    func deleteOldCompletedItems() {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ToDo")
        let userDefaults = NSUserDefaultsController().defaults
        if let retentionValue = userDefaults.value(forKey: "completeRetention") as? Int {
            let retentionDelta = Calendar.current.date(byAdding: .day, value: retentionValue * -1, to: Date())! as NSDate
            fetch.predicate = NSPredicate(format: "completedDate < %@", retentionDelta)
        } else {
            let retentionDelta = Calendar.current.date(byAdding: .day, value: -30, to: Date())! as NSDate
            fetch.predicate = NSPredicate(format: "completedDate < %@", retentionDelta)
        }
        let batchDelete = NSBatchDeleteRequest(fetchRequest: fetch)
        
        do {
            try moc.execute(batchDelete)
        } catch {
            fatalError("Failed to execute request: \(error)")
        }
    }
}
