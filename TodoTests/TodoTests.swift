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
    let cntrl = MainController()

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
        let status_label1 = cntrl.getStatusLabel(withNumber: 1, forGroup: nil)
        let status_label2 = cntrl.getStatusLabel(withNumber: 2, forGroup: nil)
        let test_group = Group(groupID: "groupID", groupName: "test group")
        let status_label3 = cntrl.getStatusLabel(withNumber: 3, forGroup: test_group)
        XCTAssertEqual(status_label1, "1 item")
        XCTAssertEqual(status_label2, "2 items")
        XCTAssertEqual(status_label3, "test group - 3 items")
    }
    
    func test_mainController_getDailyState() {
        XCTAssertEqual(cntrl.getDailyState(withDailyBoolVal: true), .on)
        XCTAssertEqual(cntrl.getDailyState(withDailyBoolVal: false), .off)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
