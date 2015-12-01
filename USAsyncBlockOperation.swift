//
//  USAsyncBlockOperation.swift
//  uShip
//
//  Created by Jason Pepas on 9/21/15.
//  Copyright (c) 2015 uShip. All rights reserved.
//

import Foundation

/*

USAsyncBlockOperation and USAsyncMainBlockOperation
---------------------------------------------------


Problem: NSBlockOperation isn't compatible with asynchronous operations.

As soon as the block returns, operation.finished becomes true, and the operation is dequeued and
released.  This completely breaks things like using NSOperationQueue.maxConcurrentOperationCount


Solution: The block must have the responsibility of setting operation.finished = true

USAsyncBlockOperation and USAsyncMainBlockOperation implement this solution.


Here is a trivial example:


class Thing
{
    let queue = NSOperationQueue()
    let service = SlowNetworkService()
    
    func doIt()
    {
        var op = USAsyncBlockOperation()
        
        op.asynchronousExecutionBlock = { [weak self, weak op] () -> Void in
            
            self?.service.getData({ (data: String) -> () in
                
                debugPrintln("Data recieved: \(data)")
                op?.asynchronousPortionIsFinished = true
                
            })
        }
        
        queue.addOperation(op)
    }
}


The above illustrates correct usage, but doesn't give you anything you can't already get with NSBlockOperation.


Here is a full working example.  Create a new "Single View" Xcode project and replace the stock ViewController
implementation with the following:


import UIKit

class ViewController: UIViewController
{
    let thing = Thing2()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        thing.doItTenTimes()
    }
}

class Thing2
{
    let queue = NSOperationQueue()
    let service = SlowNetworkService()
    
    init()
    {
        queue.maxConcurrentOperationCount = 2
    }
    
    func doIt()
    {
        var op = USAsyncBlockOperation()
        
        op.asynchronousExecutionBlock = { [weak self, weak op] () -> Void in
            
            self?.service.getData({ (data: String) -> () in
                
                debugPrintln("Data recieved: \(data)")
                op?.asynchronousPortionIsFinished = true
                
            })
        }
        
        queue.addOperation(op)
    }
    
    func doItTenTimes()
    {
        for i in 1...10 {
            doIt()
        }
    }
}

class SlowNetworkService
{
    func getData(completion:((data: String)->()))
    {
        dispatch_after(1.0, dispatch_get_main_queue()) { () -> () in
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


The above demonstrates rate-limiting asynchronous operations by using NSOperationQueue.maxConcurrentOperationCount.

Two requests will be issued (each on their own background thread), and the next two will not start until
asynchronousPortionIsFinished is set to true for the first two requests.

Note also the use of [weak self, weak op], which prevents a retain cycle between the operation and Thing2.


USAsyncMainBlockOperation:

Do not use USAsyncBlockOperation on NSOperationQueue.mainQueue.  This is a serial queue, and your long-running
asynchronous operations will block up the mainQueue while running one at a time.

Instead, define a regular NSOperationQueue, but fill it with USAsyncMainBlockOperations.  These will immedately
dispatch onto the main thread, but will also abide by NSOperationQueue.maxConcurrentOperationCount.


see also https://developer.apple.com/library/ios/documentation/Cocoa/Reference/NSOperation_class/
see also http://nshipster.com/nsoperation/

*/

class USAsyncBlockOperation: NSOperation
{
    // MARK: public interface
    
    var asynchronousExecutionBlock: (()->())?
    
    var asynchronousPortionIsFinished: Bool = false {
        didSet {
            if asynchronousPortionIsFinished == true
            {
                executing = false
                finished = true
            }
        }
    }

    // MARK: implementation

    override func start()
    {
        self.executing = true
        
        if let block = asynchronousExecutionBlock
        {
            block()
        }
        else
        {
            asynchronousPortionIsFinished = true
        }
    }
    
    override var asynchronous: Bool {
        get {
            return true
        }
    }
    
    override var executing: Bool {
        get {
            return _executing
        }
        set {
            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }
    private var _executing: Bool = false
    
    override var finished: Bool {
        get {
            return _finished
        }
        set {
            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }
    private var _finished: Bool = false
}

class USAsyncMainBlockOperation: USAsyncBlockOperation
{
    override func start()
    {
        self.executing = true
        
        if let block = asynchronousExecutionBlock
        {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                block()
            })
        }
        else
        {
            asynchronousPortionIsFinished = true
        }
    }
}

