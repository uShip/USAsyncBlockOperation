//
//  ViewController.swift
//  TestAsyncBlockOperation
//
//  Created by binaryboy on 7/30/16.
//  Copyright © 2016 Ahmed Hamdy. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let opQueue: NSOperationQueue = NSOperationQueue()
        // Do any additional setup after loading the view, typically from a nib.
        let op: USAsyncBlockOperation = USAsyncBlockOperation()
        op.asynchronousExecutionBlock = {
            print("op1")
            op.asynchronousPortionIsFinished = true
        }
        let op2: USAsyncBlockOperation = USAsyncBlockOperation()
        op2.asynchronousExecutionBlock = {
            print("op2")
            op2.asynchronousPortionIsFinished = true

        }
        let op3: USAsyncBlockOperation = USAsyncBlockOperation()
        op3.asynchronousExecutionBlock = {
            print("op3")
            op3.asynchronousPortionIsFinished = true

        }
        opQueue.maxConcurrentOperationCount = 1
        opQueue.addOperation(op)
        opQueue.addOperation(op2)
        opQueue.addOperation(op3)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
