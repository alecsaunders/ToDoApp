//
//  Group.swift
//  Todo
//
//  Created by Alec Saunders on 6/17/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Foundation

struct Group: Codable {
    var groupID: String
    var groupName: String
}


extension Group: Equatable {
    static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs.groupID == rhs.groupID && lhs.groupName == rhs.groupName
    }
}
