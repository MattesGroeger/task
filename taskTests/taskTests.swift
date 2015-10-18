/*
 * Copyright (c) 2015 Mattes Groeger
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import XCTest
@testable import task

class taskTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let expectation = self.expectationWithDescription("async call")

        TaskGroup(userInfo: UserInfo(["init": true]))
            .addTask(InlineTask { $0["foo"] = 1; print("1") })
            .addTask(DelayTask(0.3))
            .addTask(PrintTask("2"))
            .addTask(TaskGroup()
                .addTask(PrintTask("sub 1"))
                .addTask(DelayTask(0.1))
                .addTask(PrintTask("sub 2")))
            .addTask(InlineAsyncTask { finish, _ in
                doDelay(0.1) {
                    print("3")
                    finish()
                }
            })
            .addTask(InlineTask { _ in print("4") })
            .onComplete {
                print("done: ", $0)
                expectation.fulfill()
            }
            .run()

        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}

class PrintTask: Task {
    private var message: String!

    init(_ message: String) {
        self.message = message
    }

    override func run() {
        print(message)
    }
}