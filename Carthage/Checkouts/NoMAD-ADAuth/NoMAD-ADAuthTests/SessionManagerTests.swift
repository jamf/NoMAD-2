//
//  SessionManagerTests.swift
//  NoMAD-ADAuthTests
//
//  Created by Josh Wisenbaker on 12/4/17.
//  Copyright © 2018 Joel Rennich. All rights reserved.
//

import XCTest
@testable import NoMAD_ADAuth

class SessionManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSingleton() {
        let sut = SessionManager.shared
        let compSut = SessionManager.shared
        XCTAssert(sut === compSut, "Somehow we created two different SessionManagers. There should only be one.")
    }

    func testSharedInitPerf() {
        // This is an example of a performance test case.
        self.measure {
            let _ = SessionManager.shared
        }
    }

}
