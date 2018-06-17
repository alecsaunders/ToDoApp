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
    var completedDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case note
        case daily
        case createdDate
        case completedDate
    }
}

extension ToDo {
    func getDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "note": note,
            "daily": daily,
            "createdDate": createdDate.timeIntervalSince1970,
            "completedDate": completedDate?.timeIntervalSince1970 as Any
        ]
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
        let completedDateDouble = try allValues.decodeIfPresent(Double.self, forKey: .completedDate)
        if let compDateDouble = completedDateDouble {
            completedDate = Date(timeIntervalSince1970: compDateDouble)
        }
    }
}
