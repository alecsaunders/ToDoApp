//
//  SidebarFilter.swift
//  Todo
//
//  Created by Alec Saunders on 4/1/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Foundation

enum SidebarFilter {
    case all
    case daily
    case completed
}

class SidebarFilterItem: SidebarItem {
    var sbFilter: SidebarFilter?
    
    override init(withTitle title: String) {
        super.init(withTitle: title)
    }
}
