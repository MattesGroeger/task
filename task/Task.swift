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

public class Task {
    public var userInfo: [String:AnyObject]?

    public func run() {
        assert(false, "abstract, implement in sub class")
    }
}

public class AsyncTask: Task {
    internal var complete: () -> () = {}

    public func onComplete(complete: () -> ()) -> Self {
        self.complete = complete
        return self
    }
}

public protocol Cancellable {
    func cancel()
}


public class TaskGroup: AsyncTask {

    private var tasks: [Task] = []

    public func addTask(task: Task) -> Self {
        tasks.append(task)
        return self
    }

    public override func run() {
        processNextTask()
    }

    private func processNextTask() {
        if let task = tasks.first {
            if let asyncTask = task as? AsyncTask {
                asyncTask.onComplete {
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
            complete()
        }
    }
}


public class InlineTask: Task {

    private let callback: () -> ()

    init (closure: () -> ()) {
        self.callback = closure
    }

    public override func run() {
        callback()
    }
}

public class InlineAsyncTask: AsyncTask {

    private let callback: (() -> ()) -> ()

    init(closure: (() -> ()) -> ()) {
        self.callback = closure
    }

    public override func run() {
        callback {
            self.complete()
        }
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

public class DelayTask: AsyncTask {

    private var delay: Double!

    init(_ delay: Double) {
        self.delay = delay
    }

    public override func run() {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(self.delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), self.complete)
    }
}