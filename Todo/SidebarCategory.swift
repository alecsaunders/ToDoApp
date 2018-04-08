//
//  SidebarCategory.swift
//  Todo
//
//  Created by Alec Saunders on 4/1/18.
//  Copyright © 2018 Alec Saunders. All rights reserved.
//

import Foundation


class SidebarCategoryItem: SidebarItem {
    var sbCategory: Group?
    
    override init(withTitle itemName: String) {
        super.init(withTitle: itemName)
    }
}

