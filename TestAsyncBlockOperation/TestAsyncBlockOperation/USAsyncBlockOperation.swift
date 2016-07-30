//
//  USAsyncBlockOperation.swift
//  See https://github.com/uShip/USAsyncBlockOperation
//
//  Created by Jason Pepas on 9/21/15.
//  Copyright (c) 2015 uShip. All rights reserved.
//
//  Released under the terms of the MIT License.
//  See https://opensource.org/licenses/MIT

import Foundation

class USAsyncBlockOperation: NSOperation {
    // MARK: public interface

    var asynchronousExecutionBlock: (()->())?

    var asynchronousPortionIsFinished: Bool = false {
        didSet {
            if asynchronousPortionIsFinished == true {
                executing = false
                finished = true
            }
        }
    }

    // MARK: implementation

    override func start() {
        self.executing = true

        if let block = asynchronousExecutionBlock {
            block()
        } else {
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

class USAsyncMainBlockOperation: USAsyncBlockOperation {
    override func start() {
        self.executing = true

        if let block = asynchronousExecutionBlock {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                block()
            })
        } else {
            asynchronousPortionIsFinished = true
        }
    }
}

extension NSOperationQueue {

    func addOperationWithAsyncBlock(block: (()->())?) {
        
        
        let operation: USAsyncBlockOperation = USAsyncBlockOperation()
        operation.asynchronousExecutionBlock = block
        self.addOperation(operation)

    }
}
