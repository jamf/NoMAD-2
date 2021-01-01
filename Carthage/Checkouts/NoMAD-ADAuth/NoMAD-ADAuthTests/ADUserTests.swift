//
//  ADUserTests.swift
//  NoMAD
//
//  Created by Joel Rennich on 9/10/17.
//  Copyright © 2018 Joel Rennich. All rights reserved.
//

import Foundation
import XCTest
import NoMADPRIVATE
@testable import NoMAD_ADAuth

class ADUserTests : XCTestCase, NoMADUserSessionDelegate {
    func NoMADAuthenticationFailed(error: NoMADSessionError, description: String) {
        NSLog("%@", "Authentication failed called.")
    }

    
    // some setup
    
    let session = NoMADSession.init(domain: "nomad.test", user: "ftest@NOMAD.TEST", type: .AD)
    let session2 = NoMADSession.init(domain: "nomad.test", user: "ftest2@NOMAD.TEST", type: .AD)
    
    // kill any existing tickets
    
    let result = cliTask("kdestroy -a")
    
    var expectation: XCTestExpectation?
    
    override func setUp() {
        super.setUp()
    }
    
    func testAuth() {
        session.userPass = "NoMADRocks1!"
        
        expectation = self.expectation(description: "Auth Succeeded")
        session.delegate = self
        session.authenticate()
        self.waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testAuthAgain() {
        // this should not need to lookup sites
        session.userPass = "NoMADRocks1!"
        expectation = self.expectation(description: "Auth Succeeded")
        session.delegate = self
        session.authenticate()
        self.waitForExpectations(timeout: 10, handler: nil)
        session.userInfo()
    }
    
    func testAuthFail() {
        // this should fail
        session.userPass = "NotthePassword!"
        expectation = self.expectation(description: "Auth Failed")
        session.delegate = self
        session.authenticate()
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testUserLookup() {
        session.userInfo()
        print(session.userRecord)
        print(session.userRecord?.computedExireDate)
    }
    
    func testSecondAuth() {
        session2.userPass = "NoMAD21!"
        expectation = self.expectation(description: "Auth Succeeded")
        session2.delegate = self
        session2.authenticate()
        self.waitForExpectations(timeout: 10, handler: nil)
        session2.userInfo()
    }
    
    func testTicketList() {
        print(klistUtil.klist())
    }
    
    // MARK: Delegate
    
    func NoMADAuthenticationSucceded() {
        
        if expectation?.description == "Auth Succeeded" {
            print("Auth Succeeded")
            expectation?.fulfill()
        } else {
            XCTFail()
        }

    }
    
    func NoMADAuthenticationFailed(error: Error, description: String) {
        if expectation?.description == "Auth Failed" {
            print("Auth Failed")
            expectation?.fulfill()
        } else {
            XCTFail()
        }
    }
    
    func NoMADUserInformation(user: ADUserRecord) {
        print("***User Record for: \(user.fullName)***")
        print(user)
    }
}
