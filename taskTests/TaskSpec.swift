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

import Foundation
import Nimble
import Quick

class UserInfoSpec: QuickSpec {
	override func spec() {
		describe("UserInfo") {
			it("should keep data when passed through") {
				var userInfo2: UserInfo?
				let info = UserInfo(["foo": "bar"])

				func inlineFunc(userInfo: UserInfo) -> () {
					userInfo2 = userInfo
				}

				inlineFunc(info)

				expect(userInfo2).toEventually(beIdenticalTo(info))
			}

			it("should describe contents") {
				let info = UserInfo(["foo": "bar"])

				expect(info.description).to(equal("[\"foo\": bar]"))
			}
		}
	}
}

class TaskGroupSpec: QuickSpec {
	override func spec() {
		describe("TaskGroup") {
			it("should run all tasks") {
				var executed: [Int] = []

				TaskGroup()
					.addTask(InlineTask() { _ in
						executed.append(1)
					})
					.addTask(InlineTask() { _ in
						executed.append(2)
					})
					.addTask(DelayTask())
					.onComplete { _ in
						executed.append(3)
					}
					.run()
				
				expect(executed).toEventually(equal([1,2,3]))
			}

			it("should not fail when starting a running task group") {
				var doneCounter = 0

				let group = TaskGroup().addTask(InlineTask() { _ in
					doneCounter += 1
				})

				group.run()
				group.run()

				expect(doneCounter).toNotEventually(beGreaterThan(1))
			}

			context("with autoStart") {
				it("should auto start tasks") {
					var executed1: Bool?
					var executed2: Bool?

					TaskGroup(autoStart: true)
						.addTask(InlineAsyncTask() { complete, _ in
							doDelay(0.1) {
								executed1 = true
								complete()
							}
						})
						.onComplete { _ in
							executed2 = true
						}

					expect(executed1).toEventually(beTrue())
					expect(executed2).toEventually(beTrue())
				}

				it("should not run twice") {
					var doneCounter = 0

					TaskGroup(autoStart: true)
						.addTask(DelayTask())
						.onComplete { _ in
							doneCounter += 1
						}
						.run()

					expect(doneCounter).toNotEventually(beGreaterThan(1), timeout: 0.5)
				}
			}

			context("with userInfo") {
				it("should create initialy") {
					expect(TaskGroup().userInfo).toNot(beNil())
				}

				it("should pass through") {
					let userInfo1 = UserInfo()
					var userInfo2:UserInfo?
					TaskGroup(userInfo: userInfo1).addTask(InlineTask() { userInfo in
						userInfo2 = userInfo
					}).run()
					expect(userInfo2).toEventually(beIdenticalTo(userInfo1))
				}

				it("should allow adding to UserInfo") {
					var str:String?
					TaskGroup()
						.addTask(InlineAsyncTask() { complete, userInfo in
							doDelay(0.1) {
								userInfo["foo"] = "bar"
								complete()
							}
						})
						.onComplete { userInfo in
							str = userInfo["foo"] as! String
						}
						.run()
					expect(str).toEventually(equal("bar"))
				}

				it("should allow changing UserInfo") {
					var str:String?
					TaskGroup()
						.addTask(InlineAsyncTask() { complete, userInfo in
							doDelay(0.1) {
								userInfo["foo"] = "bar"
								complete()
							}
						})
						.addTask(InlineTask() { userInfo in
							userInfo["foo"] = "baz"
						})
						.onComplete { userInfo in
							str = userInfo["foo"] as! String
						}
						.run()
					expect(str).toEventually(equal("baz"))
				}
			}
		}
	}
}

func doDelay(delay: Double, _ closure: () -> ()) {
	dispatch_after(
		dispatch_time(
			DISPATCH_TIME_NOW,
			Int64(delay * Double(NSEC_PER_SEC))
		),
		dispatch_get_main_queue(), closure)
}

class DelayTask: AsyncTask {
	private var delay: Double
	init(_ delay: Double = 0.1) {
		self.delay = delay
	}
	override func run() {
		doDelay(delay) {
			self.doComplete()
		}
	}
}