//
//  TodoTests.swift
//  TodoTests
//
//  Created by Alec Saunders on 8/13/17.
//  Copyright © 2017 Alec Saunders. All rights reserved.
//

import XCTest
@testable import Todo


class TodoTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_toDoObject() {
        let nowDate = Date()
        let toDo = ToDo(id: "id", title: "title", note: "note", daily: false, createdDate: nowDate, isComplete: false, completedDate: nil, groupID: nil)
        XCTAssertEqual(toDo.id, "id")
        XCTAssertEqual(toDo.title, "title")
        XCTAssertEqual(toDo.note, "note")
        XCTAssertEqual(toDo.daily, false)
        XCTAssertEqual(toDo.createdDate, nowDate)
        XCTAssertEqual(toDo.completedDate, nil)
        XCTAssertEqual(toDo.groupID, nil)
    }
    
    func test_mainController_getStatusLabel() {
        let cntrl = MainController()
        XCTAssertEqual(1, 1)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
    }
    
}
