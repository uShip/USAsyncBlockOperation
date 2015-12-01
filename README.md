# USAsyncBlockOperation
An NSBlockOperation subclass which can tolerate asynchronous calls from within its block.

## The Problem

Calling asynchronous methods from within the block of an `NSBlockOperation` will lead to problems when being used with an operation queue which is concurrency limited (i.e. `NSOperationQueue.maxConcurrentOperationCount = 1`).

The problem is that the `NSBlockOperation` is considred "done" as soon as the block returns.  If your block simply calls an asynchronous method (e.g. a network fetch), the block will return almost immediately.

This leads to what appears to be a misbehaving serial operation queue, which executes all operations in parallel rather than serially.  However, the problem is not with the queue, but with the `NSBlockOperation`.

The following example demonstrates this problem.  Open up Xcode and create a new "Single View Application" iOS project, then replace the contents of `ViewController.swift` with the following:

```swift
import UIKit

class ViewController: UIViewController
{
    let queue = SerialOperationQueue()
    let service = SlowNetworkService()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        doItTenTimes()
    }
    
    func doItTenTimes()
    {
        for _ in 1...10 {
            doIt()
        }
    }
    
    func doIt()
    {
        let op = NSBlockOperation()
        
        op.addExecutionBlock { [weak self] () -> Void in
            
            self?.service.getData({ (data: String) -> () in
                
                debugPrint("Data recieved: \(data)")
                
            })
        }
        
        queue.addOperation(op)
    }
}

class SerialOperationQueue: NSOperationQueue
{
    override init()
    {
        super.init()
        self.maxConcurrentOperationCount = 1
    }
}

class SlowNetworkService
{
    func getData(completion:((data: String)->()))
    {
        dispatch_after(1.0, queue: dispatch_get_main_queue()) { () -> () in
            completion(data: "Hello, World!")
        }
    }
}

func dispatch_after(delay: Double, queue: dispatch_queue_t, closure: ()->())
{
    let dtime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(dtime, queue) { () -> Void in
        closure()
    }
}
```

The above simulates a slow network service which takes 1 second to return any request.  The desired behavior is to send out 10 network requests via a serial queue, such that next request isn't sent until the previous one returns.

However, the above code misbehaves.  After 1 second, all 10 results arrive at the same time.

## The Solution

The solution is to move the responsibility of setting `operation.finished` to the block itself.

Here is a revised version of `func doIt()` which solves this problem:

```swift
    func doIt()
    {
        let op = USAsyncBlockOperation()
        
        op.asynchronousExecutionBlock = { [weak self, weak op] () -> Void in
            
            self?.service.getData({ (data: String) -> () in
                
                debugPrint("Data recieved: \(data)")
                op?.asynchronousPortionIsFinished = true
                
            })
        }
        
        queue.addOperation(op)
    }
```

By using `USAsyncBlockOperation`, the operations aren't considered to be "finished" until we set `asynchronousPortionIsFinished` to `true`, which happens after the network request returns.  Thus, the serial queue behaves as we expect (you see one result per second printed out in the console).

Note also the use of `[weak self, weak op]`, which prevents retain cycles.

A more useful example would be rate-limiting our network requests, such that we only allow 3 requests in-flight at any one time.  When using `USAsyncBlockOperation`, this is as simple a setting `maxConcurrentOperationCount = 3`.

## `USAsyncMainBlockOperation`

Do not use `USAsyncBlockOperation` on `NSOperationQueue.mainQueue`.  Remember that `mainQueue` is a serial queue, and your long-running
asynchronous operations will block the `mainQueue` while running one at a time.

Instead, define a regular `NSOperationQueue`, but fill it with `USAsyncMainBlockOperation`.  These will immedately
dispatch onto the main thread, but will also abide by the `maxConcurrentOperationCount` of your queue.

## See Also:

* https://developer.apple.com/library/ios/documentation/Cocoa/Reference/NSOperation_class/
* http://nshipster.com/nsoperation/

## License

This code is released under the terms of the [MIT Licese](https://opensource.org/licenses/MIT)
