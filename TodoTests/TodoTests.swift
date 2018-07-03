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
    
    func test_mainController_viewForTableViewColumnCompletedCheckboxColumnCell() {
        let toDo = ToDo(id: "id", title: "title", note: "note", daily: false, createdDate: Date(), isComplete: false, completedDate: nil, groupID: nil)
        let toDoComplete = ToDo(id: "id", title: "title", note: "note", daily: false, createdDate: Date(), isComplete: true, completedDate: Date(), groupID: nil)
        let completeChk = NSButton()
        completeChk.setButtonType(.switch)
        completeChk.state = .off
        let cell = NSTableCellView()
        cell.subviews.append(completeChk)
        
        let outButton = cntrl.viewForTableViewColumn(completedCheckboxColumnCell: cell, atRow: 1, withItem: toDo)?.subviews[0] as? NSButton
        XCTAssertNotNil(outButton)
        XCTAssertEqual(outButton?.tag, 1)
        XCTAssertEqual(outButton?.state, .off)
        
        let outButtonComplete = cntrl.viewForTableViewColumn(completedCheckboxColumnCell: cell, atRow: 2, withItem: toDoComplete)?.subviews[0] as? NSButton
        XCTAssertNotNil(outButtonComplete)
        XCTAssertEqual(outButtonComplete?.tag, 2)
        XCTAssertEqual(outButtonComplete?.state, .on)
        
        let plainView = NSView()
        XCTAssertNil(cntrl.viewForTableViewColumn(itemColumnCell: plainView, atRow: 1, withItem: toDo))
    }
    
    func test_mainController_mapGroupsToSidebarCategories() {
        let g1 = Group(groupID: "1", groupName: "group one")
        let g2 = Group(groupID: "2", groupName: "group two")
        let g3 = Group(groupID: "3", groupName: "group three")
        let gArray = [g1, g2, g3]
        let sidebarCategoryArray = cntrl.mapGroupsToSidebarCategories(groupList: gArray)
        XCTAssertEqual(sidebarCategoryArray.count, 3)
        XCTAssertEqual(sidebarCategoryArray[0].sbCategory?.groupID, "1")
        XCTAssertEqual(sidebarCategoryArray[1].sbCategory?.groupID, "2")
        XCTAssertEqual(sidebarCategoryArray[2].sbCategory?.groupID, "3")
        XCTAssertEqual(sidebarCategoryArray[0].sidebarTitle, "group one")
        XCTAssertEqual(sidebarCategoryArray[1].sidebarTitle, "group two")
        XCTAssertEqual(sidebarCategoryArray[2].sidebarTitle, "group three")
        
        XCTAssertEqual(cntrl.mapGroupsToSidebarCategories(groupList: []).count, 0)

    }
    
    func test_mainController_changeStateOfButton() {
        let button1 = NSButton()
        button1.state = .on
        XCTAssertEqual(cntrl.changeState(ofButton: button1), .off)
        
        let button2 = NSButton()
        button2.state = .off
        XCTAssertEqual(cntrl.changeState(ofButton: button2), .on)
        
        let button3 = NSButton()
        button3.state = .init(-1)
        XCTAssertEqual(cntrl.changeState(ofButton: button3), .off)
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
    
    func test_mainController_getItemFromView() {
        let testToDo = ToDo(id: "id", title: "infoSegueTitle", note: "infoSegueNote", daily: false, createdDate: Date(), isComplete: false, completedDate: nil, groupID: nil)
        let testView = ToDoCellView()
        testView.cellToDo = testToDo
        XCTAssertEqual(cntrl.getItem(fromView: testView), testToDo)
        let failView = NSView()
        XCTAssertNil(cntrl.getItem(fromView: failView))
    }
    
    func test_mainController_getDailyState() {
        XCTAssertEqual(cntrl.getDailyState(withDailyBoolVal: true), .on)
        XCTAssertEqual(cntrl.getDailyState(withDailyBoolVal: false), .off)
    }
    
    func test_mainController_getString() {
        let isoDate = "2112-12-21T21:12:00+0000"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from: isoDate)!
        
        XCTAssertEqual(cntrl.getString(fromDate: date, withFormat: "yyyy-MM-dd"), "2112-12-21")
    }
    
    func test_mainController_setupInfoSegue() {
        let dest = InfoViewController()
        let testToDo = ToDo(id: "id", title: "infoSegueTitle", note: "infoSegueNote", daily: false, createdDate: Date(), isComplete: false, completedDate: nil, groupID: nil)
        cntrl.setupInfoSegue(dest: dest, withToDo: testToDo)
        XCTAssertEqual(dest.infoToDo?.id, testToDo.id)
        XCTAssertEqual(dest.infoToDo?.title, "infoSegueTitle")
        XCTAssertEqual(dest.infoToDo?.note, "infoSegueNote")
    }
    
    func test_mainController_toggleCompletion() {
        let testToDo = ToDo(id: "id", title: "infoSegueTitle", note: "infoSegueNote", daily: false, createdDate: Date(), isComplete: false, completedDate: nil, groupID: nil)

        let completedToDo = cntrl.toggleCompletion(forItem: testToDo, withState: 1)
        let unCompletedToDo = cntrl.toggleCompletion(forItem: completedToDo, withState: 0)
        let breakCaseToDo = cntrl.toggleCompletion(forItem: testToDo, withState: 2)
        XCTAssertEqual(completedToDo.isComplete, true)
        XCTAssertNotNil(completedToDo.completedDate)
        XCTAssertEqual(unCompletedToDo.isComplete, false)
        XCTAssertNil(unCompletedToDo.completedDate)
        XCTAssertEqual(breakCaseToDo.isComplete, false)
        XCTAssertNil(breakCaseToDo.completedDate)
    }
    
    func test_mainController_getFetchedItems() {
        let testToDo = ToDo(id: "id", title: "infoSegueTitle", note: "infoSegueNote", daily: false, createdDate: Date(), isComplete: false, completedDate: nil, groupID: nil)
        let testCategory = Group(groupID: "id", groupName: "group name")
        let testToDoArray = [testToDo]
        let testCategoryArray = [testCategory]
        XCTAssertEqual(cntrl.getFetchedItems(fromNotificationObject: nil), [])
        XCTAssertEqual(cntrl.getFetchedItems(fromNotificationObject: [1, 2, 3]), [])
        XCTAssertEqual(cntrl.getFetchedItems(fromNotificationObject: testToDoArray).count, 1)
        XCTAssertEqual(cntrl.getFetchedCategories(fromNotificationObject: nil), [])
        XCTAssertEqual(cntrl.getFetchedCategories(fromNotificationObject: [1, 2, 3]), [])
        XCTAssertEqual(cntrl.getFetchedCategories(fromNotificationObject: testCategoryArray).count, 1)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
