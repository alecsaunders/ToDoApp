//
//  ToDo.swift
//  Todo
//
//  Created by Alec Saunders on 6/16/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Foundation

struct ToDo: Codable {
    var id: String = ""
    var title: String
    var note: String
    var daily: Bool
    var createdDate: Date
    var isComplete: Bool
    var completedDate: Date?
    var groupID: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case note
        case daily
        case createdDate
        case isComplete
        case completedDate
        case groupID
    }
}

extension ToDo {
    func getDictionary() -> [String: Any] {
        var toDoDict = [
            "id": id,
            "title": title,
            "note": note,
            "daily": daily,
            "createdDate": createdDate.timeIntervalSince1970,
            "isComplete": isComplete,
            "completedDate": completedDate?.timeIntervalSince1970 as Any,
        ]
        if let gID = groupID {
            toDoDict["groupID"] = gID
        }
        return toDoDict
    }
}

extension ToDo {
    init(from decoder: Decoder) throws {
        let allValues = try decoder.container(keyedBy: CodingKeys.self)
        id = try allValues.decode(String.self, forKey: .id)
        title = try allValues.decode(String.self, forKey: .title)
        note = try allValues.decode(String.self, forKey: .note)
        daily = try allValues.decode(Bool.self, forKey: .daily)
        createdDate = try Date(timeIntervalSince1970:  (allValues.decode(Double.self, forKey: .createdDate)))
        isComplete = try allValues.decode(Bool.self, forKey: .isComplete)
        let completedDateDouble = try allValues.decodeIfPresent(Double.self, forKey: .completedDate)
        if let compDateDouble = completedDateDouble {
            completedDate = Date(timeIntervalSince1970: compDateDouble)
        }
        groupID = try allValues.decodeIfPresent(String.self, forKey: .groupID)
    }
}

extension ToDo: Equatable {
    static func == (lhs: ToDo, rhs: ToDo) -> Bool {
        return
            lhs.id == rhs.id &&
            lhs.title == rhs.title &&
            lhs.daily == rhs.daily &&
            lhs.isComplete == rhs.isComplete &&
            lhs.note == rhs.note &&
            lhs.createdDate == rhs.createdDate
    }
}
