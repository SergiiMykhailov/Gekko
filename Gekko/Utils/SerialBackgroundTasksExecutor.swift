//  Created by Sergii Mykhailov on 10/07/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation

class SerialBackgroundTasksExecutor {

typealias ExecutionBlock = (@escaping () -> Void) -> Void

    private init() {
    }

    public static let shared = SerialBackgroundTasksExecutor()

    public func enqueue(block:@escaping ExecutionBlock) {
        accessQueueSync {
            blocksQueue.append(block)

            if !isBusy {
                executeNext()
            }
        }
    }

    // MARK: Internal methods

    fileprivate func accessQueueSync(withBlock block:() -> Void) {
        accessLock.lock()
        block()
        accessLock.unlock()
    }

    fileprivate func executeNext() {
        accessQueueSync {
            if !blocksQueue.isEmpty {
                let block = blocksQueue.removeFirst()
                isBusy = true

                executionQueue.async {
                    block { [weak self] in
                        self!.isBusy = false
                    }
                }
            }
        }
    }

    // MARK: Internal fields

    fileprivate let executionQueue = DispatchQueue(label:"Gekko.BlocksExecutionQueue")
    fileprivate let accessLock = NSRecursiveLock()
    fileprivate var blocksQueue = [ExecutionBlock]()

    fileprivate var isBusy = false {
        didSet {
            if !isBusy {
                executeNext()
            }
        }
    }
}
