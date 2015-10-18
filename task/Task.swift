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

public class UserInfo: CustomStringConvertible {
    private var data: [String:AnyObject] = [:]

    convenience init() {
        self.init([:])
    }

    init(_ data: [String:AnyObject]) {
        self.data = data
    }

    public var description: String {
        return "\(data)"
    }

    public subscript(key: String) -> AnyObject? {
        get {
            return data[key]
        }
        set(newValue) {
            data[key] = newValue
        }
    }
}

public class Task {
    public var userInfo: UserInfo = UserInfo()

    public func run() {
        assert(false, "abstract, implement in subclass")
    }
}

public class AsyncTask: Task {
    private var complete: (UserInfo -> ())?

    public func onComplete(complete: UserInfo -> ()) -> Self {
        self.complete = complete
        return self
    }

    public func doComplete() {
        if let complete = complete {
            complete(userInfo)
        }
    }
}

public protocol Cancellable {
    func cancel()
}


public class TaskGroup: AsyncTask {

    private var tasks: [Task] = []
    private var autoStart: Bool = true
    private var running: Bool = false

    init(userInfo: UserInfo = UserInfo(), autoStart: Bool = false) {
        super.init()
        self.userInfo = userInfo
        self.autoStart = autoStart
    }

    public func addTask(task: Task) -> Self {
        tasks.append(task)
        if (autoStart && !running) {
            processNextTask()
        }
        return self
    }

    public override func run() {
        if !running {
            processNextTask()
        }
    }

    private func processNextTask() {
        if let task = tasks.first {
            running = true
            task.userInfo = userInfo
            if let asyncTask = task as? AsyncTask {
                asyncTask.onComplete { _ in
                    self.tasks.removeFirst()
                    self.processNextTask()
                }
                asyncTask.run()
            } else {
                task.run()
                tasks.removeFirst()
                processNextTask()
            }
        } else {
            running = false
            doComplete()
        }
    }
}


public class ConcurrentTaskGroup: AsyncTask {

    private var tasks: [Task] = []
    private var runningTasks: [Task] = []

    init(userInfo: UserInfo = UserInfo()) {
        super.init()
        self.userInfo = userInfo
    }

    public func addTask(task: Task) -> Self {
        tasks.append(task)
        return self
    }

    public override func run() {
        runningTasks += tasks
        for task in tasks {
            task.userInfo = userInfo
            if let asyncTask = task as? AsyncTask {
                asyncTask.onComplete { _ in
                    self.finishTask(task)
                }
                asyncTask.run()
            } else {
                task.run()
                finishTask(task)
            }
        }
        tasks = []
    }

    private func finishTask(task: Task) {
        if let index = runningTasks.indexOf({$0 === task}) {
            runningTasks.removeAtIndex(index)
        }
        if runningTasks.count == 0 {
            doComplete()
        }
    }
}


public class InlineTask: Task {
    private let callback: UserInfo -> ()

    init (closure: UserInfo -> ()) {
        self.callback = closure
    }

    public override func run() {
        callback(userInfo)
    }
}

public class InlineAsyncTask: AsyncTask {
    private let callback: (() -> (), UserInfo) -> ()

    init(closure: (() -> (), UserInfo) -> ()) {
        self.callback = closure
    }

    public override func run() {
        callback({
            self.doComplete()
        }, userInfo)
    }
}

public class PrintTask: Task {
    private var message: String!

    init(_ message: String) {
        self.message = message
    }

    public override func run() {
        print(message)
    }
}