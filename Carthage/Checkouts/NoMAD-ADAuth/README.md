#  NoMAD AD Authentication Framework

Congratulations, you're about to experience the blood, sweat and tears of the thousands of development hours that have gone into NoMAD's Active Directory authentication! This framework will allow you to easily add in robust AD integration to any macOS application.

This framework is written primarily in Swift 4.2 on Xcode 10 and while much of the functionality is working, it should be considered beta at this point.

## Overview

The NoMAD AD Authentication Framework allows you to present a username and password to the Framework and have it get tickets for the user and then lookup the user's information in AD. In addition the framework is:

- site aware
- able to change passwords
- able to use SSL for AD lookups
- can have the site forced or ignored
- is aware of network changes, and will mark sites to be re-discovered on changes
- perform recursive group lookups

## Basic Usage of the Framework

- Drag the framework into your project in the Embedded Binaries section of the target.
- Import NoMAD_ADAuth into your class
- Subclass NoMADUserSessionDelegate, and then add the stubs suggested to conform to the protocol
- create a NoMADSession object `let session = NoMADSession.init(domain: "nomad.test", user: "ftest@NOMAD.TEST", type: .AD)`
- set a password on the session object `session.userPass = "Secret1!"`
- set the session delegate to your class `session.delegate = self`
- try to authenticate `sesssion.authenticate()`
- the delegate callbacks will then let you know if the auth succeeded or not
